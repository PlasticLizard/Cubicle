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
    end
  end
end
