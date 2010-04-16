module Cubicle
  module Aggregation
    class AggregationView < Mustache
      attr_accessor :aggregation

      def initialize(aggregation)
        @aggregation = aggregation
      end
    end
  end
end
