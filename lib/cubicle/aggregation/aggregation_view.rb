module Cubicle
  module Aggregation
    class AggregationView < HashWithIndifferentAccess
      attr_accessor :aggregation

      def initialize(aggregation,query)

        time_now = (query.named_expressions.delete(:time_now) || Time.now).to_time

        self[:time_now] = "new Date(#{time_now.to_i*1000})"
        self[:date_today] = "new Date(#{time_now.to_date.to_time.to_i*1000})"
        self[:time_now_iso] = "#{time_now.iso8601}"
        self[:date_today_iso] = "#{time_now.strftime('%Y-%m-%d')}"

        self[:time_now_utc] = "new Date(#{time_now.utc.to_i*1000})"
        self[:date_today_utc] = "new Date(#{time_now.utc.to_date.to_time.to_i*1000})"
        self[:time_now_utc_iso] = "#{time_now.utc.iso8601}"
        self[:date_today_utc_iso] = "#{time_now.utc.strftime('%Y-%m-%d')}"

        list = aggregation.measures + aggregation.dimensions
        list.each do |m|
          self[m.name] = m.expression
        end

        self.merge!(aggregation.named_expressions)
        self.merge!(query.named_expressions)
        
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
