module Cubicle
  module Aggregation
    class AggregationManager

      attr_reader :aggregation

      def initialize(aggregation)
        @aggregation = aggregation
      end

      def database
        Cubicle.mongo.database
      end

      def collection
        database[aggregation.target_collection_name]
      end

      def target_collection_name
        aggregation.target_collection_name
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
        if query == aggregation || query.transient?
          aggregation = aggregate(query,options)
        else
          process_if_required
          aggregation = aggregation_for(query)
          #if the query exactly matches the aggregation in terms of requested members, we can issue a simple find
          #otherwise, a second map reduce is required to reduce the data set one last time
          if query.all_dimensions? || ((aggregation.name.split("_")[-1].split(".")) - query.member_names - [:all_measures]).blank?
            filter = prepare_filter(query,options[:where] || {})
          else
            aggregation = aggregate(query,:source_collection=>aggregation.name)
          end
        end

        if aggregation.blank?
          Cubicle::Data::Table.new(query,[],0) if aggregation == []
        else
          count = aggregation.count
          results = aggregation.find(filter,find_options).to_a
          aggregation.drop if aggregation.name =~ /^tmp.mr.*/
          Cubicle::Data::Table.new(query, results, count)
        end

      end

      def process(options={})
        Cubicle.logger.info "Processing #{aggregation.name} @ #{Time.now}"
        start = Time.now
        expire!
        aggregate(aggregation,options)
        #Sort desc by length of array, so that larget
        #aggregations are processed first, hopefully increasing efficiency
        #of the processing step
        aggregation.aggregations.sort!{|a,b|b.length<=>a.length}
        aggregation.aggregations.each do |member_list|
          agg_start = Time.now
          aggregation_for(aggregation.query(:defer=>true){select member_list})
          Cubicle.logger.info "#{aggregation.name} aggregation #{member_list.inspect} processed in #{Time.now-agg_start} seconds"
        end
        duration = Time.now - start
        Cubicle.logger.info "#{aggregation.name} processed @ #{Time.now}in #{duration} seconds."
      end

      def expire!
        collection.drop
        expire_aggregations!
      end

      protected

      def aggregation_collection_names
        database.collection_names.select {|col_name|col_name=~/#{aggregation.target_collection_name}_aggregation_(.*)/}
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
        filter.keys.each {|filter_key|aggregation_query.select(filter_key) unless filter_key=~/\$where/} unless filter.blank?

        dimension_names = aggregation_query.dimension_names.sort
        agg_col_name = "#{aggregation.target_collection_name}_aggregation_#{dimension_names.join('.')}"

        unless database.collection_names.include?(agg_col_name)
          source_col_name = find_best_source_collection(dimension_names)
          exec_query = aggregation.query(dimension_names + [:all_measures], :source_collection=>source_col_name, :defer=>true)
          aggregate(exec_query, :target_collection=>agg_col_name)
        end

        database[agg_col_name]
      end

      def ensure_indexes(collection_name,dimension_names)
        col = database[collection_name]
        #an index for each dimension
        dimension_names.each {|dim|col.create_index(dim)}
        #The below composite isn't working, I think because of too many fields being
        #indexed. After some thought, I think maybe this is overkill anyway. However,
        #there should be SOME way to build composite indexes for common queries,
        #so more thought is needed. Maybe cubicle can compile and analyze query
        #stats and choose indexes automatically based on usage. For now, however,
        #I'm just going to turn the thing off.
        #col.create_index(dimension_names.map{|dim|[dim,1]})
      end

      def aggregate(query,options={})
        view = AggregationView.new(aggregation,query)

        map, reduce = MapReduceHelper.generate_map_function(query), MapReduceHelper.generate_reduce_function

        options[:finalize] = MapReduceHelper.generate_finalize_function(query)
        options["query"] = expand_template(prepare_filter(query,options[:where] || {}),view)

        query.source_collection_name = options.delete(:source_collection) || query.source_collection_name || aggregation.source_collection_name

        target_collection = options.delete(:target_collection)
        target_collection ||= query.target_collection_name if query.respond_to?(:target_collection_name)

        options[:out] = target_collection unless target_collection.blank? || query.transient?

        #This is defensive - some tests run without ever initializing any collections
        return [] unless database.collection_names.include?(query.source_collection_name)

        result = database[query.source_collection_name].map_reduce(expand_template(map, view),reduce,options)

        ensure_indexes(target_collection,query.dimension_names) if target_collection

        result
      end

      def expand_template(template,view)
        return "" unless template
        return Mustache.render(template,view) if template.is_a?(String)
        if (template.is_a?(Hash))
          template.each {|key,val|template[key] = expand_template(val,view)}
          return template
        end
        template
      end

      def prepare_filter(query,filter={})
        filter.merge!(query.where) if query.respond_to?(:where) && query.where
        filter.stringify_keys!
        transient = (query.transient? || query == aggregation)
        filter.keys.each do |key|
          next if key=~/^\$.*/
          prefix = nil
          prefix = "_id" if (member = aggregation.dimensions[key])
          prefix = "value" if (member = aggregation.measures[key]) unless member

          raise "You supplied a filter that does not appear to be a member of this cubicle:#{key}" unless member

          filter_value = filter.delete(key)
          if transient
            if (member.expression_type == :javascript)
              filter_name = "$where"
              filter_value = make_filter_transient(member.expression,filter_value)
            else
              filter_name = member.field_name
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
          prefix = "_id" if (member = aggregation.dimensions[order[0]])
          prefix = "value" if (member = aggregation.measures[order[0]]) unless member
          raise "You supplied a field to order_by that does not appear to be a member of this cubicle:#{key}" unless member
          order_by << ["#{prefix}.#{order[0]}",order[1]]
        end
        order_by
      end

      def process_if_required
        return if database.collection_names.include?(target_collection_name)
        process
      end

      def make_filter_transient(filter_expression,filter_value)
        filter_value = {"$eq"=>filter_value} unless filter_value.is_a?(Hash)
        conditions = filter_value.keys.map do |operator|
          "val #{make_operator_transient(operator)} #{quote_if_required(filter_value[operator])}"
        end
        return "return (function(val){return #{conditions.join(" && ")};})(#{filter_expression})"
      end

      def make_operator_transient(operator)
        case operator
          when "$eq" then "==" #not actually a mongo operator, but added for keeping things consistent
          when "$ne" then "!="
          when "$lt" then "<"
          when "$gt" then ">"
          when "$lte" then "<="
          when "$gte" then ">="
          else raise "unsupported filter operator for filtering members of expression based members in a transient query: #{operator}"
        end
      end

      def quote_if_required(filter_value)
        (filter_value.is_a?(String) || filter_value.is_a?(Symbol)) ? "'#{filter_value}'" :filter_value
      end

    end
  end
end