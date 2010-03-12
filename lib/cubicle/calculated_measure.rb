module Cubicle
  class CalculatedMeasure < Measure

    def initialize(*args)
      opts = args.extract_options!
      opts[:aggregation_method] = :calculation
      args << opts
      super(*args)
    end
    #calculated members to not participate in the map/reduce
    #cycle. They are a finalization-time only
    #concept.
    def to_js_keys
      []
    end

  end
end
