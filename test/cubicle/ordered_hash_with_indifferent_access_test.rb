require "test_helper"

class OrderedHashWithIndifferentAccessTest < ActiveSupport::TestCase
   context "Indexing into a Cubicle::CubicleDataLevel" do
    should "provide indifferent access" do
      h = OrderedHashWithIndifferentAccess.new
      h[:hello] = "hi"
      assert_equal "hi", h["hello"]
      h["hi"] = {:hello=>:sir}
      assert_equal({:hello=>:sir}, h[:hi])
    end
    should "allow method missing to index into hash" do
      l = OrderedHashWithIndifferentAccess.new
      l.hello = "goodbye"
      assert_equal "goodbye", l[:hello]
      assert_equal "goodbye", l.hello
    end
  end
end