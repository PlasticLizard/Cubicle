require "test_helper"

class BucketizedDimensionTest < ActiveSupport::TestCase
  context "BucketizedDimension.to_js_value" do
    should "generate an appropriately structured bucketizing function" do
      dim = Cubicle::BucketizedDimension.new(:test, "this.value", 0..10, :step=>5, :bump=>1)
      assert_equal "(function(val){if(val==null || isNaN(val))return null; if (val <= 0) return '<= 0';if (val > 0 && val <= 5) return '1 - 5';if (val > 5 && val <= 10) return '6 - 10';if (val > 10) return '> 10'})(this.value)",
                   dim.to_js_value
    end
    should "use the block to generate the bucket labels if provided" do
      dim = Cubicle::BucketizedDimension.new(:test, "this.value", 0..10, :step=>5, :bump=>1) do |min,max|
        "#{min}:#{max}"
      end
      assert_equal "(function(val){if(val==null || isNaN(val))return null; if (val <= 0) return 'begin:0';if (val > 0 && val <= 5) return '1:5';if (val > 5 && val <= 10) return '6:10';if (val > 10) return '10:end'})(this.value)",
                   dim.to_js_value
    end
    should "handle decimal steps and bumps with an integer range" do
      dim = Cubicle::BucketizedDimension.new(:test, "this.value", 1..2, :step=>0.5, :bump=>0.01)
      #puts dim.to_js_value
      assert_equal "(function(val){if(val==null || isNaN(val))return null; if (val <= 1.0) return '<= 1.0';if (val > 1.0 && val <= 1.5) return '1.01 - 1.5';if (val > 1.5 && val <= 2.0) return '1.51 - 2.0';if (val > 2.0) return '> 2.0'})(this.value)",
                   dim.to_js_value
    end
  end
end
