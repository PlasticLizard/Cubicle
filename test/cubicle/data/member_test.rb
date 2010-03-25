require "test_helper"

class MemberTest < ActiveSupport::TestCase
  context "Member" do
    setup do
      @measures = [Cubicle::Measure.new(:m1, :aggregation_method=>:sum),
                   Cubicle::Measure.new(:m2, :aggregation_method=>:average)]
      @root_dim = Cubicle::Dimension.new :d1
      @child_dim = Cubicle::Dimension.new :d2
      @hierarchy = Cubicle::Data::Hierarchy.new @root_dim, @measures
      @hierarchy[:d1_a] = Cubicle::Data::Level.new(@child_dim,@hierarchy)
      @hierarchy[:d1_a][:d2_a] = [{:m1=>1.0, :m2=>2.0},{:m1=>3.0, :m2=>4.0}]
      @hierarchy[:d1_a][:d2_b] = [{:m1=>3.0, :m2=>4.0},{:m1=>5.0, :m2=>6.0}]
      @hierarchy[:d1_b] = Cubicle::Data::Level.new(@child_dim,@hierarchy)
      @hierarchy[:d1_b][:d2_c] = [{:m1=>7.0, :m2=>8.0},{:m1=>8.0,:m2=>9.0},{:m1=>10.0, :m2=>11.0}]
    end
    context "Member#measure_data" do
      should "return the member itself for leaf members" do
        assert_equal @hierarchy['d1_a']['d2_a'], @hierarchy.d1_a.d2_a.measure_data
      end
      should "return a collection aggregated children for non leaf members" do
        assert_equal [{"m1"=>4.0,"m2"=>3.0},{"m1"=>8.0,"m2"=>5.0}], @hierarchy['d1_a'].measure_data
      end
      should "return a collection of aggregated children from nested members" do
        assert_equal [{"m1"=>12.0,"m2"=>4.0},{"m1"=>25.0,"m2"=>28.0/3.0}], @hierarchy.measure_data
      end
    end
    context "Member#aggregate_children" do
      should "aggregate leaf data" do
        assert_equal({"m1"=>4.0,"m2"=>3.0}, @hierarchy['d1_a']['d2_a'].aggregate_children)
      end
      should "aggregate level data" do
        assert_equal({"m1"=>12.0,"m2"=>4.0},@hierarchy['d1_a'].aggregate_children)
      end
      should "aggregate nested level data" do
        assert_equal({"m1"=>37.0,"m2"=>(28.0/3.0 + 4.0)/2},@hierarchy.aggregate_children)  
      end
    end
  end
end