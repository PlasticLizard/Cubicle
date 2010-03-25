module Cubicle
  module Data
   module Member
        attr_accessor :member_name, :parent_level

        def measure_values
          @measure_values ||= OrderedHashWithIndifferentAccess.new
        end

        def leaf_member?
          !self.is_a?(Cubicle::Level)
        end
      end
  end
end
