require "test_helper"

class CubicleDataLevelTest < ActiveSupport::TestCase
  context "Cubicle::CubicleDataLevel#new" do
    should "succeed with no arguments" do
      assert_nothing_raised do
        Cubicle::DataLevel.new
      end
    end
    should "Choose a default name if none is provided" do
      assert_equal "Unknown Level", Cubicle::DataLevel.new.name
    end
    should "Set the name using the first argument" do
      assert_equal :me, Cubicle::DataLevel.new(:me).name
    end      
  end
  context "Indexing into a Cubicle::CubicleDataLevel" do
    should "provide indifferent access" do
      level = Cubicle::DataLevel.new
      level[:hello] = "hi"
      assert_equal "hi", level["hello"]
      level["hi"] = :hello
      assert_equal :hello, level[:hi]      
    end
    should "Provide an empty array as a default value for missing keys" do
      assert_equal [], Cubicle::DataLevel.new["hello there"]
      l = Cubicle::DataLevel.new
      l[:hi] << 1 << 2 << 3
      assert_equal [1,2,3], l[:hi]  
    end
    should "allow method missing to index into hash" do
      l = Cubicle::DataLevel.new
      l.hello = "goodbye"
      assert_equal "goodbye", l[:hello]
      assert_equal "goodbye", l.hello
    end
  end
  context "CubeDataLevel.leaf_level?" do
    should "Correctly identify a leaf level" do
      l = Cubicle::DataLevel.new(:happy)
      assert l.leaf_level?
      l[:a] = []
      assert l.leaf_level?
    end
    should "Corrently identify non-leaf level" do
      l = Cubicle::DataLevel.new(:happy)
      l[:a] = Cubicle::DataLevel.new(:sad)
      assert_not_equal true, l.leaf_level?
    end
  end
  context "CubeDataLevel.flatten" do
    should "Flatten using a provided member name" do
      l = Cubicle::DataLevel.new(:happy,{:a=>[{:a=>3,:b=>2}],:b=>[{:a=>4,:b=>1}]})
      assert_equal [2,1], l.flatten(:b)
    end
  end

end