require "test_helper"

class CubicleMetadataTest < ActiveSupport::TestCase
  context "Class level collection names" do
    should "use appropriate default values for the metadata collection" do
      assert_equal "cubicle.metadata", Cubicle::Aggregation::CubicleMetadata.collection.name
    end
  end
end