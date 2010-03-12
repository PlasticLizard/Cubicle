require "test_helper"

class AggregationTest < ActiveSupport::TestCase
  context "Executing an ad hoc query via an aggregation" do
    setup do
      Defect.create_test_data
      @results =  Cubicle::Aggregation.new("defects") do
        dimension :product, :field_name=>"product.name"
        count :total, :field_name=>"defect_id"
      end.query
    end
    should "return appropriately aggregated data" do
      assert_equal "Brush Fire Bottle Rockets", @results[0]["product"]
      assert_equal 1, @results[0]["total"]
      assert_equal "Evil's Pickling Spice", @results[1]["product"]
      assert_equal 1, @results[1]["total"]
      assert_equal "Sad Day Moonshine", @results[2]["product"]
      assert_equal 3, @results[2]["total"]
    end
  end
end