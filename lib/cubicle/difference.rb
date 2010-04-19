module Cubicle
  class Difference < CalculatedMeasure

    attr_reader :left, :right
    def initialize(member_name,left,right,opts={})
      @left, @right = left, right
      #opts[:expression]="(value.#{denominator} > 0 && value.#{numerator} ? value.#{numerator}/value.#{denominator} : 0)"
      super(member_name,opts)
    end

    def aggregate(values)
      0
    end

    def finalize_aggregation(aggregation)
      l = aggregation[left].to_f
      r = aggregation[right].to_f

      aggregation[name] = l - r
    end

    def depends_on
      [left,right]
    end

  end
end
