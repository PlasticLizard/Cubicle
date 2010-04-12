module Cubicle

  class BucketizedDimension < Dimension

    attr_accessor :step, :bump, :measure, :bucket_range, :formatter

    def initialize(dimension_name, measure, bucket_range, options={}, &block)
      super(dimension_name, options)
      @measure = measure
      @bucket_range = bucket_range
      @formatter = block
      @step = options(:bucket_size, :step) || 1
      @bump = options(:range_start_bump, :bump) || 1
      self.expression_type = :javascript
    end

    def value_expression
      return measure.to_js_value if measure.respond_to?(:to_js_value)
      measure.to_s
    end

    def expression
    generate_buckets
      @expression = "(function(val){if(val==null || isNaN(val))return null; #{@buckets.join(';')}})(#{value_expression})"
    end

#    def to_js_value
#
#    end

    private
    def generate_buckets
      @buckets = []
      prev = :begin
      @bucket_range.step(step) do |next_val|
        @buckets << bucket_javascript(prev,next_val)
        prev = next_val
      end
      @buckets << bucket_javascript(prev, :end)
    end

    def bucket_javascript(min,max)
      #min += bump unless min.is_a?(Symbol) || max.is_a?(Symbol) || min==@bucket_range.begin
      if (min == :begin)
        "if (val <= #{max}) return '#{label_for(min,max)}'"
      elsif (max == :end)
        "if (val > #{min}) return '#{label_for(min,max)}'"
      else
        "if (val > #{min} && val <= #{max}) return '#{label_for(min,max)}'"
      end
    end

    def label_for(min,max)
      min = min + bump unless min.is_a?(Symbol) || max.is_a?(Symbol)
      return formatter.call(min,max) if formatter
      if min == :begin
        "<= #{max}"
      elsif max == :end
        "> #{min}"
      else
        "#{min} - #{max}"
      end
    end
  end

end
  