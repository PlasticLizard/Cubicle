module Cubicle
  class Ratio < CalculatedMeasure

    attr_reader :numerator, :denominator
    def initialize(member_name,numerator,denominator,opts={})
      @numerator, @denominator = numerator, denominator
      opts[:expression]="(value.#{denominator} > 0 && value.#{numerator} ? value.#{numerator}/value.#{denominator} : 0)"
      super(member_name,opts)
    end

    def aggregate(values)
      0
    end

    def finalize_aggregation(aggregation)
      n = aggregation[numerator]
      d = aggregation[denominator]

      aggregation[name] = 0/0.0
      if (d > 0 && n.kind_of?(Numeric))
        aggregation[name] = n/d
      end
    end

  end
end
