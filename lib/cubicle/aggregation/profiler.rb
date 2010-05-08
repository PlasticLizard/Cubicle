module Cubicle
  module Aggregation
    class Profiler

      class << self
        def enabled?
          @@enabled ||= false
        end
        def enabled=(val)
          @@enabled = val
        end

        def max_size_in_mb
          @@max_size_in_mb = 250
        end
        def max_size_in_mb=(max)
          @@max_size_in_mb = max
        end

        def collection
          @@collection_name ||= "cubicle.profiler"
          unless Cubicle.mongo.database.collection_names.include?(@@collection_name)
            @@collection = Cubicle.mongo.database.create_collection(@@collection_name, :capped=>true, :size=>max_size_in_mb * 1000000)
          else
            @@collection ||= Cubicle.mongo.database[@@collection_name]
          end
        end
        def collection=(collection_name)
          @@collection_name = collection_name
        end

        def clear!
          collection.drop
        end
      end

      #Instance methods
      attr_reader :aggregation
      def initialize(aggregation)
        @aggregation = aggregation
      end

      def record_map_reduce_result(query,mr_options,result,reason,aggregation_info=nil)
        record_stats(result.merge({
                :action=>:map_reduce,
                :source=>query.source_collection_name,
                :dimensions=>query.dimensions.map{|m|m.name},
                :measures=>query.dimensions.map{|m|m.name},
                :query=>mr_options["query"].inspect,
                :reason=>reason,
                :aggregation_info_id=>aggregation_info ? aggregation_info._id : nil
        }))
      end

      def measure(action,stats)
        start = Time.now
        result = yield
        stop = Time.now
        record_stats(stats.merge({
                :action=>action,
                :timeMillis=>(stop-start)*1000
        }))
        result
      end

      protected
      def record_stats(stats)
        return unless self.class.enabled?
        #Sometimes, an instance of Cubicle::AdHoc is used in lieu of a pre-defined
        #aggregation, and AdHoc doesn't have a 'name' property
        name = aggregation.respond_to?(:name) ? aggregation.name : aggregation.class.name
        stats.merge!({:timestamp=>Time.now.utc,
                      :aggregation=>name})
        self.class.collection.insert(stats)
        Cubicle.logger.info "Profiler trace:#{stats.inspect}"
      end

    end
  end
end
