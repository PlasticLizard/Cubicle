module Cubicle
  class Data < Array

    attr_reader :dimension_names, :measure_names, :total_count

    def initialize(query,query_results,total_count = nil)
      @dimension_names = query.dimensions.map{|d|d.name}
      @measure_names = query.measures.map{|m|m.name}
      @time_dimension_name = query.time_dimension.name if query.respond_to?(:time_dimension) && query.time_dimension
      @time_period = query.time_period if query.respond_to?(:time_period)
      @time_range = query.time_range if query.respond_to?(:time_range)
      extract_data(query_results)
      @total_count = total_count if total_count
    end

    def hierarchize(*args)
      args = [@time_dimension_name || @dimension_names].flatten if args.blank?
      extract_dimensions args, self
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

    def extract_dimensions(dimension_names, data)
      data, dimension_names = data.dup, dimension_names.dup

      return data.map{|measures|Cubicle::DataLevel.new(:measures,measures)} if dimension_names.blank?

      dim_name = dimension_names.shift

      result = Cubicle::DataLevel.new(dim_name)
      data.each do |tuple|
        member_name = tuple.delete(dim_name.to_s) || "Unknown"
        result[member_name] << tuple
      end

      result.each do |key,value|
        result[key] = extract_dimensions(dimension_names,value)
      end

      expand_time_dimension_if_required(result)

      result
    end

    def extract_data(data)
      data.each do |result|
        new = result.dup
        self << new.delete("_id").merge(new.delete("value"))
      end
    end

    def expand_time_dimension_if_required(data_level)
      return unless data_level.leaf_level? && @time_dimension_name && @time_dimension_name.to_s == data_level.name.to_s &&
              @time_range && @time_period

      @time_range.by!(@time_period)

      @time_range.each do |date|
        formatted_date = date.to_cubicle(@time_period)
        data_level[formatted_date] = [Cubicle::DataLevel.new(:measures,{})] unless data_level.include?(formatted_date)
      end
      data_level.keys.sort!
    end
  end
end

