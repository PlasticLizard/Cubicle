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
        extract_data(query,query_results)
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

      def extract_data(query,data)
        data.each do |result|
          new = result.dup
          self << OrderedHashWithIndifferentAccess.new(new.delete("_id").merge(new.delete("value")))

          finalize_aggregations(self[-1])

          apply_aliases(query,self[-1])
        end
      end

      def finalize_aggregations(row)
        #these should be processed first, because they are often used as parts of the other calc measures
        measures.select{|m|m.distinct_count?}.each do |m|
          m.finalize_aggregation(row)
        end
        measures.select{|m|!m.distinct_count?}.each do |m|
          m.finalize_aggregation(row)
        end
      end

      def apply_aliases(query,row)
        members = query.dimensions + query.measures
        members.select{|m|m.alias_list}.each do |m|
          m.alias_list.each do |m_alias|
            row[m_alias.to_s] = row[m.name.to_s]
          end
        end
        if (query.respond_to?(:query_aliases) && query.query_aliases)
          query.query_aliases.each do |key,value|
            row[key.to_s] = row[value.to_s]
          end
        end
      end
    end
  end
end