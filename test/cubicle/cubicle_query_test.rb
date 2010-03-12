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
  end
end