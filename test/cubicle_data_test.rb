require "test_helper"

class CubicleDataTest  < ActiveSupport::TestCase
  context "Given a map-reduce query result" do
    setup do
      @raw_data =   [{"_id"=>{"company_id"=>'c1', "month"=>"2009-11"}, "value"=>{"requests"=>1.0, "transports"=>1.0}},
                     {"_id"=>{"company_id"=>'c1', "month"=>"2009-11"}, "value"=>{"requests"=>1.0, "controllable_declines"=>1.0}},
                     {"_id"=>{"company_id"=>'c1', "month"=>"2010-01"}, "value"=>{"requests"=>2.0, "transports"=>2.0}}]
      @query = Class.new do
        extend Cubicle
        dimensions :company_id, :month
        measures :requests, :transports, :controllable_declines
      end
      @data = Cubicle::Data.new(@query,@raw_data)
    end
    context "CubicleData#initialize" do
      should "merge dimension and measure hashes for each row when initialized" do
        assert_equal 3, @data.length
        assert_equal 4, @data[0].keys.length
        assert_nil @data[0]["_id"]
        assert_nil @data[0]["value"]
        assert_equal ["company_id","month","requests","transports"].sort, @data[0].keys.sort
      end
    end
    context "CubicleData.hierarchize" do
      should "hierarchize according to the dimensions of the original query when called without arguments" do
        hierarchy = @data.hierarchize
        assert_equal 1, hierarchy.length
        assert_equal :company_id, hierarchy.name
        assert_equal 2, hierarchy.c1.length
        assert_equal 2, hierarchy.c1["2009-11"].length
        assert_equal 2.0, hierarchy.c1["2010-01"][0].transports
      end
      should "hierarchize according to the order of dimensions provided" do
        hierarchy = @data.hierarchize :month, :company_id
        assert_equal 2, hierarchy.length
        assert_equal :month, hierarchy.name
        assert_equal 1, hierarchy["2009-11"].length
        assert_equal 2, hierarchy["2009-11"].c1.length
        assert_equal 1.0, hierarchy["2009-11"].c1[0].transports
      end
      should "hierarchize only the provided dimensions" do
        hierarchy = @data.hierarchize :month
        assert_equal 2, hierarchy.length
        assert hierarchy.leaf_level?
        assert_equal 1.0, hierarchy["2009-11"][0].transports
        assert_equal "c1", hierarchy["2009-11"][0].company_id
      end
    end
  end
end