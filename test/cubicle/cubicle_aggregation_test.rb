require "test_helper"

class CubicleAggregationTest < ActiveSupport::TestCase

  context "Given a query with several dimensions and measures" do
    context "Cubicle#select" do
      setup do
        Defect.create_test_data
      end
      context "without arguments" do
        setup do
          @results = DefectCubicle.query
          Time.now = "4/1/2010"
        end
        should "return a collection of appropriate aggregated values based on the cubicle parameters" do
          puts @results.inspect
          assert_equal 4, @results.length

          @results.sort!{|x,y|x.manufacture_date<=>y.manufacture_date}

          assert_equal "2009-12-09", @results[0]["manufacture_date"]
          assert_equal "2009-12", @results[0]["month"]
          assert_equal "2009", @results[0]["year"]
          assert_equal "Brush Fire Bottle Rockets", @results[0]["product"]
          assert_equal "South", @results[0]["region"]
          assert_equal "Buddy", @results[0]["operator"]
          assert_equal "Repaired", @results[0]["outcome"]
          assert_equal 1, @results[0]["total_defects"]
          assert_equal 0, @results[0]["preventable_defects"]
          assert_nil   @results[0]["conditioned_preventable"]
          assert_equal 0.43, @results[0]["total_cost"]
          assert_equal 0.43, @results[0]["avg_cost"]
          assert_equal 0, @results[0]["preventable_pct"]
          assert_equal "< $1", @results[0]["avg_cost_category"]
          assert_equal 1, @results[0]["distinct_products"]
          assert_equal 1/1, @results[0]["distinct_ratio"]
          assert_equal 1, @results[0]["inevitable_defects"]
          assert_equal 0, @results[0]["defects_this_year"]

          assert_equal "2010-01-01", @results[1]["manufacture_date"]
          assert_equal "2010-01", @results[1]["month"]
          assert_equal "2010", @results[1]["year"]
          assert_equal "Sad Day Moonshine", @results[1]["product"]
          assert_equal "West", @results[1]["region"]
          assert_equal "Franny", @results[1]["operator"]
          assert_equal "Repaired", @results[1]["outcome"]
          assert_equal 2, @results[1]["total_defects"]
          assert_equal 1, @results[1]["preventable_defects"]
          assert_equal 1, @results[1]["conditioned_preventable"]
          assert_in_delta 12.19 + 6.50, @results[1]["total_cost"], 0.0001
          assert_in_delta (12.19 + 6.50)/2.0, @results[1]["avg_cost"],0.0001
          assert_equal 0.5, @results[1]["preventable_pct"]
          assert_equal "> $5", @results[1]["avg_cost_category"]
          assert_equal 1, @results[1]["distinct_products"]
          assert_equal 1.0/2.0, @results[1]["distinct_ratio"]
          assert_equal 1, @results[1]["inevitable_defects"]
          assert_equal 2, @results[1]["defects_this_year"]

          assert_equal "2010-01-05", @results[2]["manufacture_date"]
          assert_equal "2010-01", @results[2]["month"]
          assert_equal "2010", @results[2]["year"]
          assert_equal "Evil's Pickling Spice", @results[2]["product"]
          assert_equal "Midwest", @results[2]["region"]
          assert_equal "Seymour", @results[2]["operator"]
          assert_equal "Discarded", @results[2]["outcome"]
          assert_equal 1, @results[2]["total_defects"]
          assert_equal 1, @results[2]["preventable_defects"]
          assert_equal 1, @results[2]["conditioned_preventable"]
          assert_equal 0.02, @results[2]["total_cost"]
          assert_equal 0.02, @results[2]["avg_cost"]
          assert_equal 1, @results[2]["preventable_pct"]
          assert_equal "< $1", @results[2]["avg_cost_category"]
          assert_equal 1, @results[2]["distinct_products"]
          assert_equal 1/1, @results[2]["distinct_ratio"]
          assert_equal 0, @results[2]["inevitable_defects"]
          assert_equal 1, @results[2]["defects_this_year"]

          assert_equal "2010-02-01", @results[3]["manufacture_date"]
          assert_equal "2010-02", @results[3]["month"]
          assert_equal "2010", @results[3]["year"]
          assert_equal "Sad Day Moonshine", @results[3]["product"]
          assert_equal "West", @results[3]["region"]
          assert_equal "Zooey", @results[3]["operator"]
          assert_equal "Consumed", @results[3]["outcome"]
          assert_equal 1, @results[3]["total_defects"]
          assert_equal 1, @results[3]["preventable_defects"]
          assert_equal 1, @results[3]["conditioned_preventable"]
          assert_equal 2.94, @results[3]["total_cost"]
          assert_equal 2.94, @results[3]["avg_cost"]
          assert_equal 1, @results[3]["preventable_pct"]
          assert_equal "$2.51 - $3.0", @results[3]["avg_cost_category"]
          assert_equal 1, @results[3]["distinct_products"]
          assert_equal 1/1, @results[3]["distinct_ratio"]
          assert_equal 0, @results[3]["inevitable_defects"]
          assert_equal 1, @results[3]["defects_this_year"]
        end
      end

#      context "Processing a cube" do
#        setup do
#          DefectCubicle.expire!
#          DefectCubicle.process
#        end
#        should "should create the specified aggregations" do
#          assert Cubicle.mongo.database.collection_names.include? "defect_cubicles_cubicle_aggregation_month.product.year"
#          assert Cubicle.mongo.database.collection_names.include? "defect_cubicles_cubicle_aggregation_month.region"
#        end
#
#      end
    end
  end

end