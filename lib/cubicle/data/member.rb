module Cubicle
  module Data
    module Member
      attr_accessor :member_name, :parent_level

      def measure_values
        @measure_values ||= aggregate_children()
      end

      def leaf_member?
        !self.kind_of?(Cubicle::Data::Level)
      end

      def measures
        parent_level.hierarchy.measures
      end

      def measure_data
        leaf_member? ? self : members.map{|member|member.aggregate_children}
      end

      def aggregate_children()
        Cubicle::Data.aggregate(measure_data,measures)
      end

    end
  end
end
