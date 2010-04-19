module Cubicle
  class Query
    include Dsl

    attr_reader  :time_period, :transient, :aggregation
    attr_accessor :source_collection_name
    
    def initialize(aggregation)
      @aggregation = aggregation

      @dimensions = Cubicle::MemberList.new
      @measures = Cubicle::MemberList.new
      @source_collection_name = @aggregation.target_collection_name
      @where, @from_date, @to_date, @date_dimension, @time_period, @limit, @offset = nil
      @all_dimensions, @all_measures = false, false
      @transient = false
      @by=[]
      @order_by=[]
      @from_date_filter = "$gte"
      @to_date_filter = "$lte"
      @query_aliases=HashWithIndifferentAccess.new
    end

    def clone
      Marshal.load(Marshal.dump(self))
    end

    def selected?(member = nil)
      return (@dimensions.length > 0 || @measures.length > 0) unless member
      member_name = member.kind_of?(Cubicle::Member) ? member.name : unalias(member.to_s)
      return @dimensions[member_name] ||
              @measures[member_name]
    end

    def transient?
      @transient || @aggregation.transient?
    end


    def all_measures?
      @all_measures
    end

    def all_dimensions?
      @all_dimensions
    end  

    def dimension_names
      return dimensions.map{|dim|dim.name.to_s}
    end

    def member_names
      return (dimensions + measures).map{|m|m.name.to_s}
    end

    def dimensions
      return @dimensions unless all_dimensions?
      @aggregation.dimensions.collect{|dim|convert_dimension(dim)}
    end

    def measures
      return @measures unless all_measures?
      @aggregation.measures.collect{|measure|convert_measure(measure)}
    end

    def execute(options={})
      @aggregation.execute_query(self,options)
    end

    private
    def prepare_filter
      if @from_date || @to_date
        unless time_dimension
          raise "A date range was specified for this query (#{@from_date}->#{@to_date}) however, a time dimension wasn't detected. Please use the time_dimension directive to name a field in your source data that represents the date/time you want to use to filter your query"
        end
        @time_period ||= detect_time_period || :date

        if transient? && time_dimension.expression_type != :field_name
          raise "You are attempting to filter against the derived dimension (#{time_dimension.name}=#{time_dimension.expression}) in a transient query. This is not allowed in transient queries, which only allow filtering fields specified using :field_name"
        end

        time_filter = {}

        dim_name =  time_dimension.name
        time_filter[@from_date_filter]=@from_date.utc.to_cubicle(@time_period) if @from_date
        time_filter[@to_date_filter]=@to_date.utc.to_cubicle(@time_period) if @to_date
        (@where ||= {})[dim_name] = time_filter
      end
      @where
    end

    def detect_time_period(dimension_name = (time_dimension ? time_dimension.name : nil))
      return nil unless dimension_name
      return case dimension_name.to_s.singularize
        when /.*month$/ then :month
        when /.*year$/ then :year
        when /.*quarter$/ then :quarter
        when /.*day$/ then :date
        when /.*date$/ then :date
        else nil
      end
    end

    def convert_dimension(dimension)
      return dimension if transient?
      Cubicle::Dimension.new(dimension.name, :expression=>"this._id.#{dimension.name}")
    end

    def convert_measure(measure)

      #If the measure is a ratio, we want to make
      #sure each of the ratio components will be in the output
      #Other than that, no change is required to the measure
      #However, if all measures are included, this won't be necessary
      #and would cancel out the implicit all_member inclusion. If this
      #causes a bug down the line, we may need a specific :all_members
      #flag rather than the implicit "no selections means all members"
      #shortcut.
      if (measure.kind_of?(Cubicle::CalculatedMeasure))
        select *measure.depends_on unless all_measures? || measure.depends_on.blank?
        return measure
      end

      return measure if transient?

      #when selecting from a cached map_reduce query, we no longer want to count rows, but aggregate
      #the pre-calculated counts stored in the cached collection. Therefore, any :counts become :sum
      aggregation = (measure.aggregation_method == :count && measure.options[:distinct] != true) ?
               :sum : measure.aggregation_method
      expression = "this.value.#{measure.name}"
      if (aggregation == :average)
        count_field = expression + "_count"
        expression = "#{expression}*#{count_field}"
      end
      Cubicle::Measure.new(measure.name, :expression=>expression,:aggregation_method=>aggregation, :distinct=>measure.distinct_count?)
    end

    def unalias(*name_or_names)
      return (@query_aliases[name_or_names[0]] || name_or_names[0]) unless
               name_or_names.length > 1 || name_or_names[0].is_a?(Array)

      name_or_names = name_or_names[0] if name_or_names[0].is_a?(Array)
      name_or_names.map {|name|@query_aliases[name] || name}
    end

  end
end
