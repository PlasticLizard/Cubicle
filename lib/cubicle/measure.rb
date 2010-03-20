module Cubicle
  class Measure < Member

    def initialize(*args)
      super
      @aggregation_method = self.options.delete(:aggregation_method) || default_aggregation_method
    end

    attr_accessor :aggregation_method #can be :sum, :average, :count

    def to_js_value
      return super unless aggregation_method == :count
      "((#{super}) ? 1 : 0)"
    end

    def default_aggregation_method
      :count
    end
  end
end
