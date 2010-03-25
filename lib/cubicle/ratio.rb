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
      n = aggregation[numerator].to_f
      d = aggregation[denominator].to_f

      #If the numerator is greater than zero, when we'll do the division
      #even if d is zero. This will result in a NaN, which indicates something
      #wrong with the data, which is fine. However, if the numerator is zero,
      #then maybe there just isn't any data, in which case NaN is pretty pessimistic -
      #we'll return 0 instead in this case.
      aggregation[name] = n > 0 ? n/d : 0
    end

  end
end
