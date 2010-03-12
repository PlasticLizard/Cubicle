module Cubicle
  class Aggregation
    include Cubicle
    def initialize(source_collection,&block)
      transient!
      source_collection_name source_collection
      instance_eval(&block) if block_given?
    end
  end
end
