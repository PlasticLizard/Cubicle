begin
  require "rubygems"
  require "mongo_mapper"
  require "../test_helper"

  class AggregatePluginTest < ActiveSupport::TestCase
    context "A freshly minted MongoMapper model" do
      setup do
        @model = Class.new do
          include MongoMapper::Document
          key :a_string, String
          key :a_float, Float
        end

        @model.create :a_string=>"hi", :a_float=>1.0
        @model.create :a_string=>"hi", :a_float=>2.5

        @result = @model.aggregate do
          dimension :a_string
          sum :a_float
        end.query

      end
      should "apply the aggregation to the models collection and return the result"do
        assert_equal 1, @result.length
        assert_equal 3.5, @result[0]["a_float"]
      end
    end
  end
rescue Exception => ex
  puts "MongoMapper gem not installed...plugin test skipped"
end
