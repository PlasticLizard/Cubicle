module Cubicle
  class Ratio < CalculatedMeasure

    attr_reader :numerator, :denominator
    def initialize(member_name,numerator,denominator,opts={})
      @numerator, @denominator = numerator, denominator
      opts[:expression]="(value.#{denominator} > 0 && value.#{numerator} ? value.#{numerator}/value.#{denominator} : 0)"
      super(member_name,opts)
    end

  end
end
