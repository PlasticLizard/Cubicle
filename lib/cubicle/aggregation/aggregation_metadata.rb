module Cubicle
  module Aggregation
    class AggregationMetadata
      class << self

        def collection
          @@aggregations_collection_name ||= "#{Cubicle::Aggregation::CubicleMetadata.collection.name}.aggregations"
          Cubicle.mongo.database[@@aggregations_collection_name]
        end

        def collection=(collection_name)
          @@aggregations_collection_name = collection_name
        end

        def min_records_to_reduce
          @min_records_to_reduce ||= 100
        end

        def min_records_to_reduce=(min)
          @min_records_to_reduce = min
        end

        def expire(aggregation)
          aggregation_name = case aggregation
            when String then aggregation
            when Symbol then aggregation.to_s
            when Cubicle::Aggregation::CubicleMetadata then aggregation.aggregation.name
            else aggregation.name
          end
          Cubicle.mongo.database.collection_names.each do |col|
            Cubicle.mongo.database[col].drop if col =~ /cubicle.aggregation.#{aggregation_name}._*/i
            collection.remove(:aggregation=>aggregation_name)
          end
        end
      end

      def initialize(cubicle_metadata,member_names_or_attribute_hash)
        @cubicle_metadata = cubicle_metadata
        if (member_names_or_attribute_hash.kind_of?(Hash))
          @attributes = member_names_or_attribute_hash
        else
          member_names = member_names_or_attribute_hash
          @candidate_aggregation = self.class.collection.find(
                  :aggregation=>@cubicle_metadata.aggregation.name,
                  :member_names=>{"$all"=>member_names}, :document_count=>{"$gte"=>0}).sort([:document_count, :asc]).limit(1).next_document


          #since the operator used in the query was $all, having equal lengths in the original and returned
          #member array means that they are identical, which means that regardless of the number of documents
          #in the aggregation, it is the candidate we want. Otherwise, we'll check to see if we
          #boil down the data further, or just make our soup with what we've got.
          @attributes = @candidate_aggregation if @candidate_aggregation &&
                  (@candidate_aggregation["member_names"].length == member_names.length ||
                          @candidate_aggregation["document_count"] < self.class.min_records_to_reduce)

          unless @attributes
            @attributes = HashWithIndifferentAccess.new({:aggregation=>@cubicle_metadata.aggregation.name,
                                                         :member_names=>member_names,
                                                         :document_count=>-1})

            #materialize the aggregation, and, if the operation was successful,
            #register it as available for use by future queries
            @attributes[:_id] = self.class.collection.insert(@attributes)
            materialize!
          end

        end
      end

      def target_collection_name
        "cubicle.aggregation.#{@cubicle_metadata.aggregation.name}._#{@attributes["_id"].to_s}"
      end

      def source_collection_name
        if @candidate_aggregation
          candidate = Cubicle::Aggregation::AggregationMetadata.new(@cubicle_metadata,@candidate_aggregation)
          return candidate.target_collection_name
        end
        @cubicle_metadata.aggregation.target_collection_name
      end

      def member_names; @attributes["member_names"] || []; end

      def materialized?
        document_count >= 0 &&
        (!@collection.blank? ||
         Cubicle.mongo.database.collection_names.include?(target_collection_name))
      end

      def collection
        @collection ||= Cubicle.mongo.database[target_collection_name] if materialized?
      end

      def collection=(collection)
        @collection = collection
      end

      def document_count
        @attributes["document_count"]
      end

      protected
      def update_document_count!(new_doc_count)
        self.class.collection.update({:_id=>@attributes[:_id]}, "$set"=>{:document_count=>new_doc_count})
        @attributes["document_count"]=new_doc_count
      end

      def materialize!
        unless materialized?
          exec_query = @cubicle_metadata.aggregation.query(member_names + [:all_measures],
                                                           :source_collection=>source_collection_name,
                                                           :defer=>true)
          self.collection = @cubicle_metadata.aggregation.aggregator.aggregate(exec_query,
                                                                               :target_collection=>target_collection_name)
        end
        update_document_count!(@collection.count) unless @collection.blank?
      end

    end
  end
end
