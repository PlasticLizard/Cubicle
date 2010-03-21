require "rubygems"
require "active_support"
require "mongo"
require "logger"

dir = File.dirname(__FILE__)
["mongo_environment",
 "member",
 "member_list",
 "measure",
 "calculated_measure",
 "dimension",
 "ratio",
 "duration",
 "query",
 "data_level",
 "data",
 "aggregation",
 "date_time",
 "support"].each {|lib|require File.join(dir,'cubicle',lib)}

require File.join(dir,"cubicle","mongo_mapper","aggregate_plugin") if defined?(MongoMapper::Document)

module Cubicle

  def self.register_cubicle_directory(directory_path, recursive=true)
    searcher = "#{recursive ? "*" : "**/*"}.rb"
    Dir[File.join(directory_path,searcher)].each {|cubicle| require cubicle}
  end

  def self.mongo
    @mongo ||= defined?(::MongoMapper::Document) ? ::MongoMapper : MongoEnvironment
  end

  def self.logger
    Cubicle.mongo.logger || Logger.new("cubicle.log")
  end

  def database
    Cubicle.mongo.database
  end

  def collection
    database[target_collection_name]
  end

  def transient?
    @transient ||= false
  end

  def transient!
    @transient = true
  end

  def expire!
    collection.drop
    expire_aggregations!
  end

  def aggregations
    return (@aggregations ||= [])
  end

  #DSL
  def source_collection_name(collection_name = nil)
    return @source_collection = collection_name if collection_name
    @source_collection ||= name.chomp("Cubicle").chomp("Cube").underscore.pluralize
  end
  alias source_collection_name= source_collection_name

  def target_collection_name(collection_name = nil)
    return nil if transient?
    return @target_name = collection_name if collection_name
    @target_name ||= "#{name.blank? ? source_collection_name : name.underscore.pluralize}_cubicle"
  end
  alias target_collection_name= target_collection_name

  def dimension(*args)
    dimensions << Cubicle::Dimension.new(*args)
    dimensions[-1]
  end

  def dimension_names
    return @dimensions.map{|dim|dim.name.to_s}
  end

  def dimensions(*args)
    return (@dimensions ||= Cubicle::MemberList.new) if args.length < 1
    args = args[0] if args.length == 1 && args[0].is_a?(Array)
    args.each {|dim| dimension dim }
    @dimensions
  end

  def measure(*args)
    measures << Measure.new(*args)
    measures[-1]
  end

  def measures(*args)
    return (@measures ||= Cubicle::MemberList.new) if args.length < 1
    args = args[0] if args.length == 1 && args[0].is_a?(Array)
    args.each {|m| measure m}
    @measures
  end

  def count(*args)
    options = args.extract_options!
    options[:aggregation_method] = :count
    measure(*(args << options))
  end

  def average(*args)
    options = args.extract_options!
    options[:aggregation_method] = :average
    measure(*(args << options))
    #Averaged fields need a count of non-null values to properly calculate the average
    args[0] = "#{args[0]}_count".to_sym
    count *args
  end
  alias avg average

  def sum(*args)
    options = args.extract_options!
    options[:aggregation_method] = :sum
    measure(*(args << options))
  end

  def duration(*args)
    options = args.extract_options!
    options[:in] ||= durations_in
    args << options
    measures << (dur = Duration.new(*args))
    count("#{dur.name}_count".to_sym, :expression=>dur.expression) if dur.aggregation_method == :average
  end

  def average_duration(*args)
    duration(*args)
  end
  alias avg_duration average_duration

  def total_duration(*args)
    options = args.extract_options!
    options[:aggregation_method] = :sum
    duration(*(args<<options))
  end

  def durations_in(unit_of_time = nil)
    return (@duration_unit ||= :seconds) unless unit_of_time
    @duration_unit = unit_of_time.to_s.pluralize.to_sym
  end
  alias :duration_unit :durations_in


  def ratio(member_name, numerator, denominator)
    measures << Ratio.new(member_name, numerator, denominator)
  end

  def aggregation(*member_list)
    member_list = member_list[0] if member_list[0].is_a?(Array)
    aggregations << member_list
  end

  def time_dimension(*args)
    return (@time_dimension ||= nil) unless args.length > 0
    @time_dimension = dimension(*args)
  end
  alias time_dimension= time_dimension
  alias date time_dimension
  alias time time_dimension

  def find_member(member_name)
    @dimensions[member_name] ||
            @measures[member_name]
  end

  def query(*args,&block)
    options = args.extract_options!
    query = Cubicle::Query.new(self)
    query.source_collection_name = options.delete(:source_collection) if options[:source_collection]
    query.select(*args) if args.length > 0
    if block_given?
      block.arity == 1 ? (yield query) : (query.instance_eval(&block))
    end
    query.select_all unless query.selected?
    return query if options[:defer]
    results = execute_query(query,options)
    #return results if results.blank?
    #If the 'by' clause was used in the the query,
    #we'll hierarchize by the members indicated,
    #as the next step would otherwise almost certainly
    #need to be a call to hierarchize anyway.
    query.respond_to?(:by) && query.by.length > 0 ? results.hierarchize(*query.by) : results
  end

  #noinspection RubyArgCount
  def execute_query(query,options={})
    count = 0

    find_options = {
            :limit=>query.limit || 0,
            :skip=>query.offset || 0
    }

    find_options[:sort] = prepare_order_by(query)
    filter = {}
    if query == self || query.transient?
      aggregation = aggregate(query,options)
    else
      process_if_required
      aggregation = aggregation_for(query)
      #if the query exactly matches the aggregation in terms of requested members, we can issue a simple find
      #otherwise, a second map reduce is required to reduce the data set one last time
      if ((aggregation.name.split("_")[-1].split(".")) - query.member_names - [:all_measures]).blank?
        filter = prepare_filter(query,options[:where] || {})
      else
        aggregation = aggregate(query,:source_collection=>collection.name)
      end
    end

    if aggregation.blank?
      Cubicle::Data.new(query,[],0) if aggregation == []
    else
      count = aggregation.count
      results = aggregation.find(filter,find_options).to_a
      aggregation.drop if aggregation.name =~ /^tmp.mr.*/
      Cubicle::Data.new(query, results, count)
    end

  end

  def process(options={})
    Cubicle.logger.info "Processing #{self.name} @ #{Time.now}"
    start = Time.now
    expire!
    aggregate(self,options)
    #Sort desc by length of array, so that larget
    #aggregations are processed first, hopefully increasing efficiency
    #of the processing step
    aggregations.sort!{|a,b|b.length<=>a.length}
    aggregations.each do |member_list|
      agg_start = Time.now
      aggregation_for(query(:defer=>true){select member_list})
      Cubicle.logger.info "#{self.name} aggregation #{member_list.inspect} processed in #{Time.now-agg_start} seconds"
    end
    duration = Time.now - start
    Cubicle.logger.info "#{self.name} processed @ #{Time.now}in #{duration} seconds."
  end

  protected

  def aggregation_collection_names
    database.collection_names.select {|col_name|col_name=~/#{target_collection_name}_aggregation_(.*)/}
  end

  def expire_aggregations!
    aggregation_collection_names.each{|agg_col|database[agg_col].drop}
  end

  def find_best_source_collection(dimension_names, existing_aggregations=self.aggregation_collection_names)
    #format of aggregation collection names is source_cubicle_collection_aggregation_dim1.dim2.dim3.dimn
    #this next ugly bit of algebra will create 2d array containing a list of the dimension names in each existing aggregation
    existing = existing_aggregations.map do |agg_col_name|
      agg_col_name.gsub("#{target_collection_name}_aggregation_","").split(".")
    end

    #This will select all the aggregations that contain ALL of the desired dimension names
    #we are sorting by length because the aggregation with the least number of members
    #is likely to be the most efficient data source as it will likely contain the smallest number of rows.
    #this will not always be true, and situations may exist where it is rarely true, however the alternative
    #is to actually count rows of candidates, which seems a bit wasteful. Of course only the profiler knows,
    #but until there is some reason to believe the aggregation caching process needs be highly performant,
    #this should do for now.
    candidates = existing.select {|candidate|(dimension_names - candidate).blank?}.sort {|a,b|a.length <=> b.length}

    #If no suitable aggregation exists to base this one off of,
    #we'll just use the base cubes aggregation collection
    return target_collection_name if candidates.blank?
    "#{target_collection_name}_aggregation_#{candidates[0].join('.')}"

  end

  def aggregation_for(query)
    return collection if query.all_dimensions?

    aggregation_query = query.clone
    #If the query needs to filter on a field, it had better be in the aggregation...if it isn't a $where filter...
    filter = (query.where if query.respond_to?(:where))
    filter.keys.each {|filter_key|aggregation_query.select(filter_key) unless filter_key=~/^\$.*/} unless filter.blank?

    dimension_names = aggregation_query.dimension_names.sort
    agg_col_name = "#{target_collection_name}_aggregation_#{dimension_names.join('.')}"

    unless database.collection_names.include?(agg_col_name)
      source_col_name = find_best_source_collection(dimension_names)
      exec_query = query(dimension_names + [:all_measures], :source_collection=>source_col_name, :defer=>true)
      aggregate(exec_query, :target_collection=>agg_col_name)
    end

    database[agg_col_name]
  end

  def ensure_indexes(collection_name,dimension_names)
    #an index for each dimension
    dimension_names.each {|dim|database[collection_name].create_index([dim,Mongo::ASCENDING])}
    #and a composite
    database[collection_name].create_index(dimension_names)
  end

  def aggregate(query,options={})
    map, reduce = generate_map_function(query), generate_reduce_function
    options[:finalize] = generate_finalize_function(query)
    options["query"] = prepare_filter(query,options[:where] || {})

    query.source_collection_name ||= source_collection_name

    target_collection = options.delete(:target_collection)
    target_collection ||= query.target_collection_name if query.respond_to?(:target_collection_name)

    options[:out] = target_collection unless target_collection.blank? || query.transient?

    #This is defensive - some tests run without ever initializing any collections
    return [] unless database.collection_names.include?(query.source_collection_name)

    result = database[query.source_collection_name].map_reduce(map,reduce,options)

    ensure_indexes(target_collection,query.dimension_names) if target_collection

    result
  end

  def prepare_filter(query,filter={})
    filter.merge!(query.where) if query.respond_to?(:where) && query.where
    filter.stringify_keys!
    transient = (query.transient? || query == self)
    filter.keys.each do |key|
      next if key=~/^\$.*/
      prefix = nil
      prefix = "_id" if (member = self.dimensions[key])
      prefix = "value" if (member = self.measures[key]) unless member

      raise "You supplied a filter that does not appear to be a member of this cubicle:#{key}" unless member

      filter_value = filter.delete(key)
      if transient
        if (member.expression_type == :javascript)
          filter_name = "$where"
          filter_value = "'#{filter_value}'" if filter_value.is_a?(String) || filter_value.is_a?(Symbol)
          filter_value = "(#{member.expression})==#{filter_value}"
        else
          filter_name = member.expression
        end
      else
        filter_name = "#{prefix}.#{member.name}"
      end
      filter[filter_name] = filter_value
    end
    filter
  end

  def prepare_order_by(query)
    order_by = []
    query.order_by.each do |order|
      prefix = "_id" if (member = self.dimensions[order[0]])
      prefix = "value" if (member = self.measures[order[0]]) unless member
      raise "You supplied a field to order_by that does not appear to be a member of this cubicle:#{key}" unless member
      order_by << ["#{prefix}.#{order[0]}",order[1]]
    end
    order_by
  end

  def process_if_required
    return if database.collection_names.include?(target_collection_name)
    process
  end


  def generate_keys_string(query)
    "{#{query.dimensions.map{|dim|dim.to_js_keys}.flatten.join(", ")}}"
  end

  def generate_values_string(query = self)
    "{#{query.measures.map{|measure|measure.to_js_keys}.flatten.join(", ")}}"
  end

  def generate_map_function(query = self)
    <<MAP
    function(){emit(#{generate_keys_string(query)},#{generate_values_string(query)});}
MAP
  end

  def generate_reduce_function()
    <<REDUCE
  function(key,values){
	var output = {};
	values.forEach(function(doc){
        for(var key in doc){
			if (doc[key] || doc[key] == 0){
				output[key] = output[key] || 0;
				output[key]  += doc[key];
			}
		}
	  });
	return output;
  }
REDUCE
  end

  def generate_finalize_function(query = self)
    <<FINALIZE
    function(key,value)
    {

     #{  (query.measures.select{|m|m.aggregation_method == :average}).map do |m|
      "value.#{m.name}=value.#{m.name}/value.#{m.name}_count;"
    end.join("\n")}
    #{  (query.measures.select{|m|m.aggregation_method == :calculation}).map do|m|
      "value.#{m.name}=#{m.expression};";
    end.join("\n")}
    return value;
    }
FINALIZE
  end
end