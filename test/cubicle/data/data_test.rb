require "test_helper"

class DataTest < ActiveSupport::TestCase
  context "Data#aggregate" do
    should "Aggregate a given table of numbers according to the provided measures" do
      #[{"m1"=>1.0, "m2"=>1.0, "m3"=>1.0}, {"m1"=>2.0, "m2"=>3.0, "m3"=>4.0}, {"m1"=>3.0, "m2"=>5.0, "m3"=>7.0}]
      data=3.times.inject([]) do |set,index|
        set << HashWithIndifferentAccess.new({:m1=>1.0 * index+1, :m2=>2.0 * index+1, :m3=>3.0 * index+1})
      end
      measures = [Cubicle::Measure.new(:m1, :aggregation_method=>:sum),
                  Cubicle::Measure.new(:m2, :aggregation_method=>:count),
                  Cubicle::Measure.new(:m3, :aggregation_method=>:average)]
      aggregation = Cubicle::Data.aggregate(data,measures)
      assert_equal 6.0, aggregation[:m1]
      assert_equal 9.0, aggregation[:m2]
      assert_equal 4.0, aggregation[:m3]
    end
    should "Finalize the aggregation" do
      #[{"m1"=>1.0, "m2"=>1.0}, {"m1"=>2.0, "m2"=>3.0}, {"m1"=>3.0, "m2"=>5.0}]
      data=3.times.inject([]) do |set,index|
        set << HashWithIndifferentAccess.new({:m1=>1.0 * index+1, :m2=>2.0 * index+1})
      end
      measures = [Cubicle::Measure.new(:m1, :aggregation_method=>:sum),
                  Cubicle::Measure.new(:m2, :aggregation_method=>:count),
                  Cubicle::Ratio.new(:m3, :m1, :m2)]
      aggregation = Cubicle::Data.aggregate(data,measures)
      assert_equal 6.0/9.0, aggregation[:m3]
    end
  end
end