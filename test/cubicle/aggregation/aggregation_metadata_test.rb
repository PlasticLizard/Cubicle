require "test_helper"

class AggregationMetadataTest < ActiveSupport::TestCase
  context "Class level collection names" do
    should "use appropriate default values for the aggregations collection" do
      assert_equal "cubicle.metadata.aggregations", Cubicle::Aggregation::AggregationMetadata.collection.name
    end
  end

  context "AggregationMetadata.update_document_count" do
    setup do
      @cm = Cubicle::Aggregation::CubicleMetadata.new(DefectCubicle)
    end
    should "update the document count for a given aggregation instance" do
      agg_info = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product])
      agg_info.send(:update_document_count!,1024)
      assert_equal 1024, agg_info.document_count
      assert_equal false,agg_info.materialized? 
    end
  end

  context "AggregationMetadata#new" do
    setup do
      @cm = Cubicle::Aggregation::CubicleMetadata.new(DefectCubicle)
    end
    should "create initialize an instance of AggregationMetadata in the database" do
      agg_info = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product,:region])
      assert /cubicle.aggregation.DefectCubicle._+/ =~ agg_info.target_collection_name
      assert_equal [:product,:region], agg_info.member_names
      assert_equal false, agg_info.materialized?
      assert_nil agg_info.collection
    end
    should "fetch an existing aggregation from the database" do
      ag = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product,:region])
      ag.send(:update_document_count!,1)
      col_name = ag.target_collection_name
      assert_equal col_name, Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product,:region]).target_collection_name
    end
    should "ignore an existing aggregation that does not satisfy all fields" do
      ag = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product])
      ag.send(:update_document_count!,1)
      col_name = ag.target_collection_name
      assert col_name != Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product,:region]).target_collection_name
    end
    should "select an existing aggregation with rows below the minimum threshold instead of creating a new one" do
      agg_info = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product,:region,:operator])
      agg_info.send(:update_document_count!,99)
      assert_equal agg_info.target_collection_name, Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product]).target_collection_name
    end

    should "ignore an existing aggregation with too many rows, but store that aggregation as a candidate source for use when materializing the aggregation" do
      agg_info = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product,:region,:operator])
      agg_info.send(:update_document_count!,101)
      new_agg_info = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product])
      assert agg_info.target_collection_name != new_agg_info.target_collection_name
      assert_equal agg_info.target_collection_name, new_agg_info.source_collection_name
    end
  end

  context "AggregationMetadata#materialize!" do
    should "run a map reduce and produce the resulting collection" do
      Defect.create_test_data
      DefectCubicle.process
      @cm = Cubicle::Aggregation::CubicleMetadata.new(DefectCubicle)
      agg_info = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product])
      aggregation = agg_info.collection
      assert_not_nil aggregation
      assert aggregation.count > 0
      assert_equal aggregation.count, agg_info.document_count
    end
  end

  context "AggregationMetadata.expire" do
    should "drop any aggregation columns and remove metadata rows from the database" do
      Defect.create_test_data
      DefectCubicle.process
      @cm = Cubicle::Aggregation::CubicleMetadata.new(DefectCubicle)
      agg_info = Cubicle::Aggregation::AggregationMetadata.new(@cm,[:product])

      assert Cubicle.mongo.database.collection_names.include?(agg_info.target_collection_name)
      assert Cubicle::Aggregation::AggregationMetadata.collection.find(:aggregation=>"DefectCubicle").count > 0

      Cubicle::Aggregation::AggregationMetadata.expire(@cm)

      assert !Cubicle.mongo.database.collection_names.include?(agg_info.target_collection_name)
      assert_equal 0, Cubicle::Aggregation::AggregationMetadata.collection.find(:aggregation=>"DefectCubicle").count
    end
  end
end