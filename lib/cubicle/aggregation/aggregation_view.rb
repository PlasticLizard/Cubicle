module Cubicle
  module Aggregation
    class AggregationView < HashWithIndifferentAccess
      attr_accessor :aggregation

      def initialize(aggregation)

        super[:time_now] = "new Date(#{Time.now.to_i*1000})"

        self.merge!(aggregation.named_expressions)

        list = aggregation.measures + aggregation.dimensions
        list.each do |m|
          super[m.name] = m.expression
        end
        self.each do |key,value|
          self[key] = expand_template(value)
        end
      end

      def expand_template(template)
        while (template =~ /\{\{\w+\}\}/)
          template = Mustache.render(template,self)
        end
        template
      end
    end
  end
end
