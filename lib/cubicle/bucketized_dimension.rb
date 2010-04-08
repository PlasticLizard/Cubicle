module Cubicle

  class BucketizedDimension < Dimension

    attr_accessor :step, :bump, :value_expression, :bucket_range, :formatter

    def initialize(dimension_name, value_expression, bucket_range, options={}, &block)
      super(dimension_name, options)
      @value_expression = value_expression
      @bucket_range = bucket_range
      @formatter = block
      @step = options(:bucket_size, :step) || 1
      @bump = options(:range_start_bump, :bump) || 1
    end

    def to_js_value
      generate_buckets
      "(function(val){if(val==null || isNaN(val))return null; #{@buckets.join(';')}})(#{value_expression})"
    end

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
      min += bump unless min.is_a?(Symbol) || max.is_a?(Symbol) || min==@bucket_range.begin
      if (min == :begin)
        "if (val < #{max}) return '#{label_for(min,max)}'"
      elsif (max == :end)
        "if (val > #{min}) return '#{label_for(min,max)}'"
      else
        "if (val >= #{min} && val <= #{max}) return '#{label_for(min,max)}'"
      end
    end

    def label_for(min,max)
      return formatter.call(min,max) if formatter
      if min == :begin
        "< #{max}"
      elsif max == :end
        "> #{min}"
      else
        "#{min} - #{max}"
      end
    end


  end

  <<BUCKETIZE
  (function(val){
    if(val == null || isNaN(val)) return null;
	if(val < 5) return '< 5';
    if (val >= 6 && val <= 10) return '6 - 10'
    if (val >= 11 && val <= 15) return '11 - 15'
    return '> 10';
  })(val)
BUCKETIZE



end
  