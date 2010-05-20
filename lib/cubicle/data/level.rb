module Cubicle
  module Data
    class Level < OrderedHashWithIndifferentAccess

      def initialize(dimension,parent_level=nil)
        @dimension = dimension
        @parent_level = parent_level
        super() {|hash,key|hash[key]=[]}#Always have an array freshly baked when strangers call
      end

      attr_reader   :dimension, :parent_level
      attr_accessor :missing_member_default

      alias member_names keys
      alias members values

      def name
        @dimension.name
      end

      def flatten(member_name = nil, opts={}, &block)

        default_val = opts[:default] || @missing_member_default || 0

        self.values.inject([]) do |output, data|
          value = data.measure_values
          value.missing_member_default = default_val if value.respond_to?(:missing_member_default)

          if block_given?
            flat_val = block.arity == 1 ? (yield value) : (value.instance_eval(&block))
          end
          flat_val ||= value[member_name] if member_name && value.include?(member_name)
          flat_val ||= default_val
          output << flat_val
        end
      end

      def leaf_level?
        return self.length < 1 ||
                !self[self.keys[0]].is_a?(Cubicle::Data::Level)
      end

      def []=(key,val)
        prepare_level_member(val,key,self)
        super(key.to_s,val)
      end

      def hierarchy
        parent_level || self
      end

      private
      def prepare_level_member(member,member_name,parent_level)
        member.class_eval("include Cubicle::Data::Member")
        member.member_name = member_name
        member.parent_level = parent_level
      end

    end
  end
end
