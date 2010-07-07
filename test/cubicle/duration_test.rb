require "test_helper"

class DurationTest < ActiveSupport::TestCase
  context "Querying a cubicle with durations" do
    setup do
      #record 1, ms1 = 1/1/2000, ms2 = 1/2/2000, ms3=1/4/2000, ms4=1/23/2000
      #record 2, ms1 = 1/1/2000, ms2 = 1/3/2000, ms3=1/5/2000, ms4=1/29/2000
      Defect.create_duration_test_data
    end
    should "correctly calculate durations for each activity" do
      results = DefectCubicle.query do
        select :all
        by :operator
      end
      a1 = results["a"][0]
      a2 = results["b"][0]

      assert_equal 1 * 60 * 60 * 24, a1["ms1_to_ms2_average"]
      assert_equal 2 * 60 * 60 * 24, a1["ms2_to_ms3_sum"]
      assert_equal 3,                a1["total_duration"]
      assert_equal 22/7.0,           a1["total_duration_in_weeks"]

      assert_equal 2 * 60 * 60 * 24, a2["ms1_to_ms2_average"]
      assert_equal 2 * 60 * 60 * 24, a2["ms2_to_ms3_sum"]
      assert_equal 4,                a2["total_duration"]
      assert_equal 28/7.0,           a2["total_duration_in_weeks"]
    end
    should "correctly aggregate durations" do
      results = DefectCubicle.query do
        select :all_measures, :product
      end
      results = results[0]

      assert_equal 1.5 * 60 * 60 * 24, results["ms1_to_ms2_average"]
      assert_equal 4 * 60 * 60 * 24,   results["ms2_to_ms3_sum"]
      assert_equal 3.5,                results["total_duration"]

    end
    should "respect the condition argument" do
      results = DefectCubicle.query do
        select :all_measures, :product
      end
      results = results[0]

      assert_equal 3, results["conditional_duration"]
    end
    should "calculate duration_since via elapsed" do
      Time.now = "1/10/2000"
      results = DefectCubicle.query do
        select :all_measures, :product
      end
      results = results[0]

      assert_equal((6+5)/2.0, results["ms3_to_now_average"])

    end
    should "calculate named duration_since via age_since" do
      Time.now = "1/10/2000"
      results = DefectCubicle.query do
        select :all_measures, :product
      end
      results = results[0]

      assert_equal((6+5)/2.0, results["avg_time_since_ms3"])

    end
  end

end