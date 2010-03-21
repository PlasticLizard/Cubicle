module Cubicle
  module Aggregation
  class AdHoc
    include Cubicle::Aggregation
    def initialize(source_collection,&block)
      transient!
      source_collection_name source_collection
      instance_eval(&block) if block_given?
    end
    end
  end
end
