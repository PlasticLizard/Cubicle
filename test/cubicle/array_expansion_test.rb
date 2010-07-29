require "test_helper"

class ArrayExpansionTest < ActiveSupport::TestCase
  context "CubicleQuery#select" do
    setup do
      Defect.create_test_data
    end
    should "process" do
      DefectAuditCubicle.process
    end
    should "expand array and correctly aggregate results" do
      query_results = DefectAuditCubicle.query do
        select :average_score
        by     :auditor
      end
      assert_equal 3, query_results.length;
      puts query_results.inspect
      assert_equal 8/3.0, query_results["Nina"][0]["average_score"]
      assert_equal 7/2.0, query_results["Pinta"][0]["average_score"]
      assert_equal 7/2.0, query_results["Santa Maria"][0]["average_score"]
    end
    should "aggregate parent document dimensions correctly" do
      query_results = DefectAuditCubicle.query do
        select :average_score
        by :product
      end
      assert_equal 3, query_results.length
      assert_equal 8/3.0, query_results["Sad Day Moonshine"][0]["average_score"]
      assert_equal 7/2.0, query_results["Evil's Pickling Spice"][0]["average_score"]
      assert_equal 7/2.0, query_results["Brush Fire Bottle Rockets"][0]["average_score"]
    end
  end
end