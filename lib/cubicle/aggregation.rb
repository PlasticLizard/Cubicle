module Cubicle
  module Aggregation
    include Dsl

    def aggregator
      @aggregator ||= AggregationManager.new(self)
    end

    def transient?
      @transient ||= false
    end

    def transient!
      @transient = true
    end

    def expire!
      aggregator.expire!
    end

    def process(*args)
      aggregator.process(*args)
    end

    def aggregations
      return (@aggregations ||= [])
    end

    def dimension_names
      return @dimensions.map{|dim|dim.name.to_s}
    end

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

    def execute_query(query,options)
      aggregator.execute_query(query,options)
    end
  end
end