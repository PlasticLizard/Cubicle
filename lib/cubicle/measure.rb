module Cubicle
  class Measure < Member

    def initialize(*args)
      super
      @aggregation_method = self.options.delete(:aggregation_method) || default_aggregation_method
    end

    attr_accessor :aggregation_method #can be :sum, :average, :count

#    def to_js_value
#      return super unless aggregation_method == :count
#      "((#{super}) ? 1 : 0)"
#    end

    def expression
      return "((#{super}) ? 1 : 0)" if aggregation_method == :count && options[:distinct] != true
      super
    end

    def default_aggregation_method
      :count
    end

    def distinct_count?
      aggregation_method==:count && options[:distinct]
    end

    def aggregate(values)
      return nil if values.blank?
      sum = values.inject(0){|total,val|total+val}
      aggregation_method == :average ? sum/values.length : sum
    end

    def finalize_aggregation(aggregation)
      aggregation[name] = aggregation[name].length if distinct_count? &&
              aggregation[name] &&
              aggregation[name].respond_to?(:length)
      aggregation
    end
  end
end
