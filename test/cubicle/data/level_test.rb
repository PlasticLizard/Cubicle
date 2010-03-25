require "test_helper"

class LevelTest < ActiveSupport::TestCase
  context "Cubicle::CubicleDataLevel#new" do
    should "Set the name using the dimension provided" do
      assert_equal :me, Cubicle::Data::Level.new(Cubicle::Dimension.new(:me)).name
    end      
  end
 
  context "CubeDataLevel.leaf_level?" do
    should "Correctly identify a leaf level" do
      l = Cubicle::Data::Level.new(Cubicle::Dimension.new(:happy))
      assert l.leaf_level?
      l[:a] = []
      assert l.leaf_level?
    end
    should "Corrently identify non-leaf level" do
      l = Cubicle::Data::Level.new(:happy)
      l[:a] = Cubicle::Data::Level.new(:sad)
      assert_not_equal true, l.leaf_level?
    end
  end
  context "CubeDataLevel.flatten" do
    should "Flatten using a provided member name" do
      l = Cubicle::Data::Level.new(Cubicle::Dimension.new(:happy))
      l[:a] = [{:a=>3,:b=>2}]
      l[:b] = [{:a=>4,:b=>1}]
      assert_equal [2,1], l.flatten(:b)
    end
  end
  context "CubeDataLevel[]=" do
    should "Make any passed in value into a configured Cubicle::DataLevel::Member" do
      level  = Cubicle::Data::Level.new(Cubicle::Dimension.new(:baby))
      member = {}
      level[:a] = member
      assert member.kind_of?(Cubicle::Data::Member)
      assert_equal member.member_name, :a
      assert_equal level, member.parent_level
    end
  end

end