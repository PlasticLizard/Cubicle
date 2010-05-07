module Cubicle
  module Aggregation
    class CubicleMetadata

      class << self

        def collection
          @@collection_name ||= "cubicle.metadata"
          Cubicle.mongo.database[@@collection_name]
        end
        def collection=(collection_name)
          @@collection_name = collection_name
        end
      end

      attr_reader :aggregation
      def initialize(aggregation)
        @aggregation = aggregation
      end

      def aggregation_for(member_names = [])
        AggregationMetadata.new(self,member_names)
      end

      def expire!
        AggregationMetadata.expire(self)
      end

      def update_processing_stats
        Cubicle.logger.info "Processing #{aggregation.name} @ #{Time.now}"
        start = Time.now
        error = nil
        begin
          yield if block_given?
          Cubicle.logger.info "#{aggregation.name} processed @ #{Time.now}."
          result=:success
        rescue RuntimeError=>ex
          error = ex
          result = :error
          fail
        ensure
          stop = Time.now
          duration = stop - start
          stats = {:timestamp=>Time.now.utc,
                   :aggregation=>aggregation.name,
                   :last_duration_in_seconds=>duration,
                   :result=>result
          }

          #If an error occurred, we want to record the message, but
          #not overwrite the timestamp of the last successful process.
          #If all was well, we want to indicate the now is the last
          #succesful processing of the aggregation.
          result == :error ? stats[:last_error] = error : stats[:last_processed]=stop

          self.class.collection.update({:aggregation=>aggregation.name},#criteria
                                       {"$set"=>stats},#data
                                       :upsert=>true)#upsert

        end
      end
    end
  end
end
