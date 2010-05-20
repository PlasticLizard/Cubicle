module Cubicle
  module Data
    class Hierarchy < Cubicle::Data::Level
      include Member

      attr_reader :measures
      def initialize(root_dimension,measures)
        super(root_dimension)
        @measures = measures
        @member_name = name
      end

      def self.hierarchize_table(table, dimension_names=nil)
        dimension_names = [table.time_dimension_name || table.dimension_names].flatten if dimension_names.blank?
        Cubicle::Data::Hierarchy.extract_dimensions(dimension_names,table,table.dup)
      end
      private

      def self.extract_dimensions(dimension_names, data, table,parent_level=nil)
        data, dimension_names = data.dup, dimension_names.dup

        return data if dimension_names.blank?

        dim_name = dimension_names.shift
        dim = table.dimensions.find{|d|d.name==dim_name}
        level = parent_level ? Cubicle::Data::Level.new(dim,parent_level) : Cubicle::Data::Hierarchy.new(dim,data.measures)
        data.each do |tuple|
          member_name = tuple.delete(dim_name.to_s) || "Unknown"
          (level[member_name] ||= []) << tuple
        end

        level.each do |key,value|
          level[key] = Cubicle::Data::Hierarchy.extract_dimensions(dimension_names,value,table,level)
        end

        Cubicle::Data::Hierarchy.expand_time_dimension_if_required(level,table)

        level
      end

      def self.expand_time_dimension_if_required(data_level,table)
        return unless data_level.leaf_level? && table.time_dimension_name && table.time_dimension_name.to_s == data_level.name.to_s &&
                table.time_range && table.time_period

        table.time_range.by!(table.time_period)

        table.time_range.each do |date|
          formatted_date = date.to_cubicle(table.time_period)
          data_level[formatted_date] = [OrderedHashWithIndifferentAccess.new] unless data_level.include?(formatted_date)
        end
        data_level.keys.sort!
      end
    end
  end
end
