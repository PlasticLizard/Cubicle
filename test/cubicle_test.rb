require "test_helper"

class CubicleTest < ActiveSupport::TestCase

  context "Given a query with several dimensions and measures" do
    context "Cubicle#select" do
      setup do
        Defect.create_test_data
      end
      context "without arguments" do
        setup do
          @results = DefectCubicle.query
        end
        should "return a collection of appropriate aggregated values based on the cubicle parameters" do
          assert_equal 4, @results.length

          assert_equal "2009-12-09", @results[0]["manufacture_date"]
          assert_equal "2009-12", @results[0]["month"]
          assert_equal "2009", @results[0]["year"]
          assert_equal "Brush Fire Bottle Rockets", @results[0]["product"]
          assert_equal "South", @results[0]["region"]
          assert_equal "Buddy", @results[0]["operator"]
          assert_equal "Repaired", @results[0]["outcome"]
          assert_equal 1, @results[0]["total_defects"]
          assert_equal 0, @results[0]["preventable_defects"]
          assert_equal 0.43, @results[0]["total_cost"]
          assert_equal 0.43, @results[0]["avg_cost"]
          assert_equal 0, @results[0]["preventable_pct"]

          assert_equal "2010-01-01", @results[1]["manufacture_date"]
          assert_equal "2010-01", @results[1]["month"]
          assert_equal "2010", @results[1]["year"]
          assert_equal "Sad Day Moonshine", @results[1]["product"]
          assert_equal "West", @results[1]["region"]
          assert_equal "Franny", @results[1]["operator"]
          assert_equal "Repaired", @results[1]["outcome"]
          assert_equal 2, @results[1]["total_defects"]
          assert_equal 1, @results[1]["preventable_defects"]
          assert_in_delta 0.001, 12.97, @results[1]["total_cost"]
          assert_in_delta 0.001, 6.485, @results[1]["avg_cost"]
          assert_equal 0.5, @results[1]["preventable_pct"]

          assert_equal "2010-01-05", @results[2]["manufacture_date"]
          assert_equal "2010-01", @results[2]["month"]
          assert_equal "2010", @results[2]["year"]
          assert_equal "Evil's Pickling Spice", @results[2]["product"]
          assert_equal "Midwest", @results[2]["region"]
          assert_equal "Seymour", @results[2]["operator"]
          assert_equal "Discarded", @results[2]["outcome"]
          assert_equal 1, @results[2]["total_defects"]
          assert_equal 1, @results[2]["preventable_defects"]
          assert_equal 0.02, @results[2]["total_cost"]
          assert_equal 0.02, @results[2]["avg_cost"]
          assert_equal 1, @results[2]["preventable_pct"]

          assert_equal "2010-02-01", @results[3]["manufacture_date"]
          assert_equal "2010-02", @results[3]["month"]
          assert_equal "2010", @results[3]["year"]
          assert_equal "Sad Day Moonshine", @results[3]["product"]
          assert_equal "West", @results[3]["region"]
          assert_equal "Zooey", @results[3]["operator"]
          assert_equal "Consumed", @results[3]["outcome"]
          assert_equal 1, @results[3]["total_defects"]
          assert_equal 1, @results[3]["preventable_defects"]
          assert_equal 2.94, @results[3]["total_cost"]
          assert_equal 2.94, @results[3]["avg_cost"]
          assert_equal 1, @results[3]["preventable_pct"]
        end
      end
      context "when specifying a dimension" do
        setup do
          @results = DefectCubicle.query(:product, :all_measures)
        end
        should "return the specified subset of data, including all measures" do
          assert_equal 3, @results.length

          assert_equal "Brush Fire Bottle Rockets", @results[0]["product"]
          assert_equal 1, @results[0]["total_defects"]
          assert_equal 0, @results[0]["preventable_defects"]
          assert_equal 0.43, @results[0]["total_cost"]
          assert_equal 0.43, @results[0]["avg_cost"]
          assert_equal 0, @results[0]["preventable_pct"]
        end

      end
      context "when specifying a dimension using an alias" do
        setup do
          @results = DefectCubicle.query(:date, :all_measures)
        end
        should "return the specified subset of data, including all measures" do
          assert_equal 4, @results.length
          assert_equal "2009-12-09", @results[0]["manufacture_date"]
          assert_equal 1, @results[0]["total_defects"]
          assert_equal 0, @results[0]["preventable_defects"]
          assert_equal 0.43, @results[0]["total_cost"]
          assert_equal 0.43, @results[0]["avg_cost"]
          assert_equal 0, @results[0]["preventable_pct"]
        end
      end
      context "when specifying a dimension from a transient query" do
        setup do
          #DefectCubicle.transient!
          @results = DefectCubicle.query do |q|
            q.transient!
            q.select :product, :all_measures
          end
        end
        should "return the specified subset of data, including all measures" do
          assert_equal 3, @results.length

          assert_equal "Brush Fire Bottle Rockets", @results[0]["product"]
          assert_equal 1, @results[0]["total_defects"]
          assert_equal 0, @results[0]["preventable_defects"]
          assert_equal 0.43, @results[0]["total_cost"]
          assert_equal 0.43, @results[0]["avg_cost"]
          assert_equal 0, @results[0]["preventable_pct"]
        end

      end
      context "when specifying a dimensional filter on a transient query" do
        setup do
          @results = DefectCubicle.query do
            transient!
            select :product, :all_measures
            where  :product=>"Sad Day Moonshine"
          end
        end
        should "return a filtered subset of data" do
          assert_equal 1, @results.length
          assert_equal "Sad Day Moonshine", @results[0]["product"]
          assert_equal 3, @results[0]["total_defects"]
          assert_equal 2, @results[0]["preventable_defects"]
          assert_equal 15.91, @results[0]["total_cost"]
          assert_equal 15.91/3, @results[0]["avg_cost"]
          assert_equal 2/3.0, @results[0]["preventable_pct"]
        end

      end
      context "when specifying a dimensional filter on a transient query using an alias" do
        setup do
          #DefectCubicle.transient!
          @results = DefectCubicle.query do
            transient!
            select :manufacture_date, :all_measures
            where  :date=>"2009-12-09"
          end
          puts @results.inspect
        end
        should "return a filtered subset of data" do
          assert_equal 1, @results.length
          assert_equal "2009-12-09", @results[0]["manufacture_date"]
          assert_equal 1, @results[0]["total_defects"]
          assert_equal 0, @results[0]["preventable_defects"]
          assert_equal 0.43, @results[0]["total_cost"]
          assert_equal 0.43, @results[0]["avg_cost"]
          assert_equal 0, @results[0]["preventable_pct"]
        end

      end
      context "when specifying a dimensional filter on a non-transient query" do
        setup do
          @results = DefectCubicle.query do
            select :product, :all_measures
            where  :product=>"Sad Day Moonshine"
          end
        end
        should "return a filtered subset of data" do
          assert_equal 1, @results.length
          assert_equal "Sad Day Moonshine", @results[0]["product"]
          assert_equal 3, @results[0]["total_defects"]
          assert_equal 2, @results[0]["preventable_defects"]
          assert_in_delta 0.0001, 15.91, @results[0]["total_cost"]
          assert_in_delta 0.0001, 15.91/3, @results[0]["avg_cost"]
          assert_in_delta 0.0001, 2/3.0, @results[0]["preventable_pct"]
        end

      end
      context "when specifying a dimensional filter on a non-transient query using an alias" do
        setup do
          @results = DefectCubicle.query do
            select :date, :all_measures
            where  :date=>"2009-12-09"
          end
          puts @results.inspect
        end
        should "return a filtered subset of data" do
          assert_equal 1, @results.length
          assert_equal "2009-12-09", @results[0]["manufacture_date"]
          assert_equal 1, @results[0]["total_defects"]
          assert_equal 0, @results[0]["preventable_defects"]
          assert_equal 0.43, @results[0]["total_cost"]
          assert_equal 0.43, @results[0]["avg_cost"]
          assert_equal 0, @results[0]["preventable_pct"]
        end

      end
      context "when specifying a dimensional filter on a non-transient query using $where" do
        setup do
          @results = DefectCubicle.query do
            select :product, :all_measures
            where  "$where"=>"this._id.product=='Sad Day Moonshine'"
          end
          puts @results.inspect
        end
        should "return a filtered subset of data" do
          assert_equal 1, @results.length
          assert_equal "Sad Day Moonshine", @results[0]["product"]
          assert_equal 3, @results[0]["total_defects"]
          assert_equal 2, @results[0]["preventable_defects"]
          assert_in_delta 0.0001, 15.91, @results[0]["total_cost"]
          assert_in_delta 0.0001, 15.91/3, @results[0]["avg_cost"]
          assert_equal 2/3.0, @results[0]["preventable_pct"]
        end

      end
      context "when specifying a dimensional filter on a transient query using $where" do
        setup do
          @results = DefectCubicle.query do
            transient!
            select :product, :all_measures
            where  "$where"=>"this.product.name=='Sad Day Moonshine'"
          end
        end
        should "return a filtered subset of data" do
          assert_equal 1, @results.length
          assert_equal "Sad Day Moonshine", @results[0]["product"]
          assert_equal 3, @results[0]["total_defects"]
          assert_equal 2, @results[0]["preventable_defects"]
          assert_equal 15.91, @results[0]["total_cost"]
          assert_equal 15.91/3, @results[0]["avg_cost"]
          assert_equal 2/3.0, @results[0]["preventable_pct"]
        end

      end
      context "when specifying a dimensional filter for an expression based dimension on a transient query" do
        setup do
          @results = DefectCubicle.query do
            transient!
            select :product,:all_measures
            where  :month=>"2010-01"
          end
          puts @results.inspect
        end
        should "return a filtered subset of data" do
          assert_equal 2, @results.length
          assert_equal "Evil's Pickling Spice", @results[0]["product"]
          assert_equal "Sad Day Moonshine", @results[1]["product"]
        end

      end
      context "when specifying a sort order on a transient query" do
        setup do
          @results = DefectCubicle.query do
            transient!
            select :product,:all_measures
            order_by [:product, :desc]
          end
        end
        should "return sorted data" do
          assert_equal 3, @results.length
          assert_equal "Sad Day Moonshine", @results[0]["product"]
          assert_equal "Evil's Pickling Spice", @results[1]["product"]
          assert_equal "Brush Fire Bottle Rockets", @results[2]["product"]
        end

      end
      context "when specifying a sort order on a non transient query" do
        setup do
          @results = DefectCubicle.query do
            select :product,:all_measures
            order_by [:product, :desc]
          end
          puts @results.inspect
        end
        should "return sorted data" do
          assert_equal 3, @results.length
          assert_equal "Sad Day Moonshine", @results[0]["product"]
          assert_equal "Evil's Pickling Spice", @results[1]["product"]
          assert_equal "Brush Fire Bottle Rockets", @results[2]["product"]
        end

      end
      context "Processing a cube" do
        setup do
          DefectCubicle.expire!
          DefectCubicle.process
        end
        should "should create the specified aggregations" do
          puts Cubicle.mongo.database.collection_names.inspect
          assert Cubicle.mongo.database.collection_names.include? "defect_cubicles_cubicle_aggregation_month.product.year"
          assert Cubicle.mongo.database.collection_names.include? "defect_cubicles_cubicle_aggregation_month.region"
        end

      end
    end
  end

end