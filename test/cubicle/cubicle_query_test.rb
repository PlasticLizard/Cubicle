require "test_helper"

class CubicleQueryTest < ActiveSupport::TestCase
  context "CubicleQuery#select" do
    setup do
      Defect.create_test_data
    end
    should "raise an exception when given a non-existent member" do
      assert_raise RuntimeError do
        DefectCubicle.query do
          select :does_not_exist
        end
      end
    end
    should "query the underlying data source of cubicle rather than the persistent cache when :transient=>true" do
      query = DefectCubicle.query :defer=>true  do
        transient!
        select :product, :total_defects
      end
      query.execute()
      assert_equal "defects", query.source_collection_name
    end
    should "query the persistent cache when transient=>false" do
      query = DefectCubicle.query :defer=>true do
        select :product, :total_defects
      end
      query.execute()
      assert_equal "defect_cubicles_cubicle", query.source_collection_name
    end
    should "Select dimensions in the by clause" do
      query_results = DefectCubicle.query do
        select :all_measures
        by :product
      end
      assert_equal :product, query_results.name
      assert_equal "Brush Fire Bottle Rockets", query_results.member_names[0]
    end
    should "Select aliased dimensions in the by clause" do
      query_results = DefectCubicle.query do
        select :all_measures
        by :date
      end
      assert_equal :manufacture_date, query_results.name
      assert_equal "2009-12-09", query_results.member_names[0]
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
        assert_equal 2, @results[0]["conditioned_preventable"]
        assert_equal 21.63, @results[0]["total_cost"]
        assert_equal 21.63/3, @results[0]["avg_cost"]
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
        assert_equal 2, @results[0]["conditioned_preventable"]
        assert_in_delta 21.63, @results[0]["total_cost"],0.0001
        assert_in_delta 21.63/3, @results[0]["avg_cost"],0.0001
        assert_in_delta 2/3.0, @results[0]["preventable_pct"],0.0001
      end

    end
    context "when specifying a dimensional filter on a non-transient query using an alias" do
      setup do
        @results = DefectCubicle.query do
          select :date, :all_measures
          where  :date=>"2009-12-09"
        end
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
      end
      should "return a filtered subset of data" do
        assert_equal 1, @results.length
        assert_equal "Sad Day Moonshine", @results[0]["product"]
        assert_equal 3, @results[0]["total_defects"]
        assert_equal 2, @results[0]["preventable_defects"]
        assert_equal 2, @results[0]["conditioned_preventable"]
        assert_in_delta 21.63, @results[0]["total_cost"],0.0001
        assert_in_delta 21.63/3, @results[0]["avg_cost"],0.0001
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
        assert_equal 2, @results[0]["conditioned_preventable"]
        assert_equal 21.63, @results[0]["total_cost"]
        assert_equal 21.63/3, @results[0]["avg_cost"]
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
      end
      should "return a filtered subset of data" do
        assert_equal 2, @results.length
        assert_equal "Evil's Pickling Spice", @results[0]["product"]
        assert_equal "Sad Day Moonshine", @results[1]["product"]
      end
    end
    context "when specifying a special dimensional filter for an expression based dimension on a transient query" do
      setup do
        @results = DefectCubicle.query do
          transient!
          select :product,:all_measures
          where  :month=>{"$ne"=>"2010-01"}
        end
      end
      should "return a filtered subset of data" do
        assert_equal 2, @results.length
        assert_equal "Brush Fire Bottle Rockets", @results[0]["product"]
        assert_equal "Sad Day Moonshine", @results[1]["product"]
      end
    end
    context "when specifying several special dimensional filters for an expression based dimension on a transient query" do
      setup do
        @results = DefectCubicle.query do
          transient!
          select :product,:all_measures
          where  :month=>{"$gt"=>"2010-01", "$lte"=>"2010-02"}
        end
      end
      should "return a filtered subset of data" do
        assert_equal 1, @results.length
        assert_equal "Sad Day Moonshine", @results[0]["product"]
      end
    end
    context "when specifying a special dimensional filter for an expression based bucketized dimension on a transient query" do
      setup do
        @results = DefectCubicle.query do
          transient!
          select :product, :all_measures
          where :avg_cost_category=>{"$ne"=>"< $1"}
        end
      end
      should "return a filtered subset of data" do
        puts @results.inspect
        assert_equal 1, @results.length
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
      end
      should "return sorted data" do
        assert_equal 3, @results.length
        assert_equal "Sad Day Moonshine", @results[0]["product"]
        assert_equal "Evil's Pickling Spice", @results[1]["product"]
        assert_equal "Brush Fire Bottle Rockets", @results[2]["product"]
      end

    end
    context "when requesting YTD" do
      setup do
        Time.now = "2010-01-04"
        @results = DefectCubicle.query do
          select :date, :all_measures
          year_to_date
        end
      end
      should "present YTD data based on Time.now" do
        assert_equal 1, @results.length
        assert_in_delta 18.69, @results[0]["total_cost"],0.0001
      end
    end
    context "when requesting MTD in a non-transient query do" do
      setup do
        Time.now = "2010-01-05"
        @results = DefectCubicle.query do
          select :month, :all_measures
          month_to_date
        end
      end
      should "present MTD data based on Time.now" do
        assert_equal 1, @results.length
        assert_in_delta 18.71, @results[0]["total_cost"],0.0001
      end
    end
    context "when requesting MTD in a transient query do" do
      setup do
        Time.now = "2010-01-05"
        @results = DefectCubicle.query do
          transient!
          select :month, :all_measures
          month_to_date
        end
      end
      should "present MTD data based on Time.now" do
        assert_equal 1, @results.length
        assert_in_delta 18.71, @results[0]["total_cost"],0.0001
      end
    end
    context "when requesting for_the_last_complete 1.months" do
      setup do
        Time.now = "2010-01-30"
        @results = DefectCubicle.query do
          select :month, :all_measures
          for_the_last_complete :month
        end
      end
      should "present data for the previous month" do
        assert_equal 1, @results.length
        assert_equal 0.43, @results[0]["total_cost"]
      end
    end
    context "when requesting an exclusive date range" do
      setup do
        Time.now = "2010-01-30"
        @results = DefectCubicle.query do
          select :month, :all_measures
          for_the_last_complete 12.months
          by :month
        end
      end
      should "provide an entry for each month, even months without data" do
        assert_equal [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.0], @results.flatten(:total_defects)
        assert_equal "2009-01", @results.keys[0]
        assert_equal "2009-12", @results.keys[-1]
      end
    end
    context "when requesting a date range with no results" do
      setup do
        Time.now = "2020-01-01"
        @results = DefectCubicle.query do
          select :month, :all_measures
          for_the_last_complete 12.months
          by :month
        end
      end
      should "provide an empty entry for each month" do
        assert_equal 12, @results.count
        assert_equal [0,0,0,0,0,0,0,0,0,0,0,0], @results.flatten(:total_defects)
      end
    end
    context "Date filters against native Time types" do
      setup do
        Time.now = "2010-01-30"
        Cubicle::DateTime.db_time_format = :native
        @results = DefectCubicle.query do
          time_dimension :manufacture_time
          select :month, :all_measures
          for_the_last_complete :month
        end
      end
      should "dance like a butterfly and sting like a bee" do
        assert_equal 1, @results.length
        assert_equal 0.43, @results[0]["total_cost"]
      end
      teardown do
        Cubicle::DateTime.db_time_format = :iso8601
      end
    end
    context "when a query level alias has been specified" do
      should "respect the alias in the by clause" do
        query_results = DefectCubicle.query do
          alias_member :date=>:my_crazy_date
          select :all_measures
          by :my_crazy_date
        end
        assert_equal :manufacture_date, query_results.name
        assert_equal "2009-12-09", query_results.member_names[0]
      end
      should "respect the alias in the where clause" do
        results = DefectCubicle.query do
          alias_member :product=>:my_crazy_product
          select :product, :all_measures
          where  :my_crazy_product=>"Sad Day Moonshine"
        end
        assert_equal 1, results.length
        assert_equal "Sad Day Moonshine", results[0]["product"]
        assert_equal 3, results[0]["total_defects"]
        assert_equal 2, results[0]["preventable_defects"]
        assert_equal 2, results[0]["conditioned_preventable"]
        assert_in_delta 21.63, results[0]["total_cost"],0.0001
        assert_in_delta 21.63/3, results[0]["avg_cost"],0.0001
        assert_in_delta 2/3.0, results[0]["preventable_pct"],0.0001
      end
      should "respect the alias in the order by clause" do
        results = DefectCubicle.query do
          alias_member :product=>:my_crazy_product
          select :product,:all_measures
          order_by [:my_crazy_product, :desc]
        end
        assert_equal 3, results.length
        assert_equal "Sad Day Moonshine", results[0]["product"]
        assert_equal "Evil's Pickling Spice", results[1]["product"]
        assert_equal "Brush Fire Bottle Rockets", results[2]["product"]
      end
      should "calculate distinct counts properly" do
        results = DefectCubicle.query do
          select :year, :distinct_products
          where :year=>"2010"
        end
        puts results.inspect
        assert_equal 1, results.length
        assert_equal 2, results[0]["distinct_products"]
      end
    end
    context "Aggregation level 'define' calls" do
      should "override the default of Time.now" do
        results = DefectCubicle.query do
          transient!
          select :year, :defects_this_year
        end
        puts results.inspect
        assert_equal 2, results.length
        assert_equal 0, results[0].defects_this_year
        assert_equal 4, results[1].defects_this_year  
      end
    end
    context "Query level 'define' calls" do
      should "override the defaults" do
        results = DefectCubicle.query do
          transient!
          define :time_now, "2009-01-01".to_time

          select :year, :defects_this_year
        end
        puts results.inspect
        assert_equal 2, results.length
        assert_equal 1, results[0].defects_this_year
        assert_equal 0, results[1].defects_this_year
      end
    end
    context "Grouping by day" do
      should "not cause the system to hang" do
        Time.now = "2010-01-01"
        results = DefectCubicle.query do
          select :defects_this_year
          by :date
          for_the_last 5.days
        end
        puts results.inspect
        assert_not_nil results
      end

    end
  end
end