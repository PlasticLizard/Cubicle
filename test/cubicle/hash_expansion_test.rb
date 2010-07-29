require "test_helper"

class HashExpansionTest < ActiveSupport::TestCase
  context "CubicleQuery#select" do
    setup do
      Defect.create_test_data
    end
    should "process" do
      HashPipeCubicle.process
    end
    should "expand array and correctly aggregate results" do
      query_results = HashPipeCubicle.query do
        select :total_score
        by     :hash_key
      end
      assert_equal 4, query_results.length
      assert_equal -1,query_results["defect"][0]["total_score"]
      assert_equal -2,query_results["metaphor"][0]["total_score"]
      assert_equal -3,query_results["must"][0]["total_score"]
      assert_equal 1,query_results["die"][0]["total_score"]
    end
    should "aggregate parent document dimensions correctly" do
      query_results = HashPipeCubicle.query do
        select :total_score
        by :product
      end
      assert_equal 2, query_results.length
      assert_equal -3,query_results["Sad Day Moonshine"][0]["total_score"]
      assert_equal -2,query_results["Evil's Pickling Spice"][0]["total_score"]
    end
  end
end