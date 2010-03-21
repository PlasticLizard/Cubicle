module Cubicle
  module MongoMapper
    module AggregatePlugin
      module ClassMethods
        def aggregate(&block)
          return Cubicle::Aggregation::AdHoc.new(self.collection_name,&block)
        end
      end

      def self.included(model)
        model.plugin AggregatePlugin
      end
    end
  end
end

MongoMapper::Document.append_inclusions(Cubicle::MongoMapper::AggregatePlugin)
