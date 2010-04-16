module Cubicle
  module Data
    class Table < Array
      attr_reader :total_count, :dimensions, :measures, :time_dimension_name, :time_range, :time_period

      def initialize(query,query_results,total_count = nil)
        @dimensions = Marshal.load(Marshal.dump(query.dimensions))
        @measures   = Marshal.load(Marshal.dump(query.measures))
        @time_dimension_name = query.time_dimension.name if query.respond_to?(:time_dimension) && query.time_dimension
        @time_period = query.time_period if query.respond_to?(:time_period)
        @time_range = query.time_range if query.respond_to?(:time_range)
        extract_data(query_results)
        @total_count = total_count if total_count
      end

      def dimension_names
        @dimensions.map{|d|d.name}
      end

      def measure_names
        @measures.map{|m|m.name}
      end

      def hierarchize(*args)
        Cubicle::Data::Hierarchy.hierarchize_table(self,args)
      end
      alias hierarchize_by hierarchize
      alias by hierarchize

      def records_per_page=(records_per_page)
        @records_per_page=records_per_page
      end

      def total_pages
        if (!defined?(@total_count))
          raise "Cannot find the total number of pages without setting the total count"
        end

        if (!defined?(@records_per_page))
          raise "Cannot find the total number of pages without setting the number of records per page"
        end

        (@total_count.to_f / @records_per_page.to_f).ceil
      end

      private

      def extract_data(data)
        data.each do |result|
          new = result.dup
          #The ugly way to resolve distinct counts
          if (new["value"])
            new["value"].each do |k,v|
              new["value"][k] = v.length if v && v.is_a?(Hash)    
            end
          end
          self << OrderedHashWithIndifferentAccess.new(new.delete("_id").merge(new.delete("value")))
        end
      end
    end
  end
end