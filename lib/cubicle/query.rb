module Cubicle
  class Query

    attr_reader  :time_period, :transient
    attr_accessor :source_collection_name
    def initialize(cubicle)
      @cubicle = cubicle

      @dimensions = Cubicle::MemberList.new
      @measures = Cubicle::MemberList.new
      @source_collection_name = @cubicle.target_collection_name
      @where, @from_date, @to_date, @date_dimension, @time_period, @limit, @offset = nil
      @all_dimensions, @all_measures = false, false
      @transient = false
      @by=[]
      @order_by=[]
    end

    def select_all
      select :all_dimensions, :all_measures
    end

    def selected?(member = nil)
      return (@dimensions.length > 0 || @measures.length > 0) unless member
      member_name = member.kind_of?(Cubicle::Member) ? member.name : member.to_s
      return @dimensions[member_name] ||
              @measures[member_name]
    end

    def transient?
      @transient || @cubicle.transient?
    end

    def transient!
      @transient = true
      @source_collection_name = nil
    end

    def all_measures?
      @all_measures
    end

    def all_dimensions?
      @all_dimensions
    end

    def select(*args)
      args = args[0] if args[0].is_a?(Array)

      if (args.include?(:all))
        select_all
        return
      end

      if (args.include?(:all_measures))
        @all_measures = true
        @measures = Cubicle::MemberList.new
      end
      if (args.include?(:all_dimensions))
        @all_dimensions = true
        @dimensions = Cubicle::MemberList.new
      end

      return if args.length == 1 && selected?(args[0])

      found=[:all_measures,:all_dimensions]

      if args.length == 1 && !all_dimensions? && args[0].is_a?(Cubicle::Dimension)
        @dimensions << convert_dimension(args.pop)
      elsif args.length == 1 && !all_measures? && args[0].is_a?(Cubicle::Measure)
        @measures << convert_measure(args.pop)
      else
        #remove from the list any dimensions or measures that are already
        #selected. This allows select to be idempotent,
        #which is useful for ensuring certain members are selected
        #even though the user may already have selected them previously
        args.each do |member_name|
          if (member = @cubicle.dimensions[member_name])
            @dimensions << convert_dimension(member)
          elsif (member = @cubicle.measures[member_name])
            @measures << convert_measure(member)
          end
          found << member_name if member || selected?(member_name)
        end
      end
      args = args - found
      raise "You selected one or more members that do not exist in the underlying data source:#{args.inspect}" unless args.blank?
      self
    end

    def limit(in_limit = nil)
      return @limit unless in_limit
      @limit = in_limit
      return self
    end

    def offset(in_offset = nil)
      return @offset unless in_offset
      @offset = in_offset
      return self
    end

    alias skip offset

    def by(*args)
      return @by unless args.length > 0

      #We'll need these in the result set
      select *args

      #replace any alias names with actual member names
      @by = args.map{|member_name|@cubicle.find_member(member_name).name}
      return if @time_dimension #If a time dimension has been explicitly specified, the following isn't helpful.

      #Now let's see if we can find ourselves a time dimension
      if (@cubicle.time_dimension && time_dimension.included_in?(args))
        time_dimension(@cubicle.time_dimension)
      else
        args.each do |by_member|
          if (detected = detect_time_period by_member)
            time_dimension by_member
            @time_period = detected
            break
          end
        end
      end
    end

    def order_by(*args)
      return @order_by unless args.length > 0
      args.each do |order|
        @order_by << (order.is_a?(Array) ? order : [order,:asc])
      end
    end

    def time_range(date_range = nil)
      return nil unless date_range || @from_date || @to_date
      return @from_date, @to_date = date_range.first, date_range.last if date_range
      ((@from_date || Time.now)..(@to_date || Time.now))
    end

    def time_dimension(dimension_name = nil)
      return (@time_dimension ||= @cubicle.time_dimension) unless dimension_name
      @time_dimension = @cubicle.dimensions[dimension_name]
      raise "No dimension matching the name #{dimension_name} could be found in the underlying data source" unless @time_dimension
      select @time_dimension unless selected?(dimension_name)
    end
    alias date_dimension time_dimension

    def last(duration,as_of = Time.now)
      duration = 1.send(duration) if [:year,:month,:week,:day].include?(duration)
      period = duration.parts[0][0]
      @from_date = duration.ago(as_of).advance(period=>1)
      @to_date = as_of
      self
    end
    alias for_the_last last

    def last_complete(duration,as_of = Time.now)
      duration = 1.send(duration) if [:year,:month,:week,:day].include?(duration)
      period = duration.parts[0][0]
      @to_date = as_of.advance(period=>-1).beginning_of(period)
      @from_date = duration.ago(@to_date).advance(period=>1)
    end
    alias for_the_last_complete last_complete

    def next(duration,as_of = Time.now)
      duration = 1.send(duration) if [:year,:month,:week,:day].include?(duration)
      period = duration.parts[0][0]
      @to_date = duration.from_now(as_of).advance(period=>-1)
      @from_date = as_of
      self
    end
    alias for_the_next next

    def this(period,as_of = Time.now)
      @from_date = as_of.beginning_of(period)
      @from_date = as_of.beginning_of(period)
      @to_date = as_of
      self
    end

    def from(time = nil)
      return @from_date unless time
      @from_date = if time.is_a?(Symbol)
        Time.send(time) if Time.respond_to?(time)
        Date.send(time).to_time if Date.respond_to?(time)
      else
        time.to_time
      end
      self
    end

    def until(time = nil)
      return @to_date unless time
      @to_date = if time.is_a?(Symbol)
        Time.send(time) if Time.respond_to?(time)
        Date.send(time).to_time if Date.respond_to?(time)
      else
        time.to_time
      end
      self
    end

    def ytd(as_of = Time.now)
      this :year, as_of
    end
    alias year_to_date ytd

    def mtd(as_of = Time.now)
      this :month, as_of
    end
    alias month_to_date mtd

    def where(filter = nil)
      return prepare_filter unless filter
      (@where ||= {}).merge!(filter)
      self
    end

    def dimension_names
      return dimensions.map{|dim|dim.name.to_s}
    end

    def dimensions
      return @dimensions unless all_dimensions?
      @cubicle.dimensions.collect{|dim|convert_dimension(dim)}
    end

    def measures
      return @measures unless all_measures?
      @cubicle.measures.collect{|measure|convert_measure(measure)}
    end

    def execute(options={})
      @cubicle.execute_query(self,options)
    end

    private
    def prepare_filter
      if @from_date || @to_date
        unless time_dimension
          raise "A date range was specified for this query (#{@from_date}->#{@to_date}) however, a time dimension wasn't detected. Please use the time_dimension directive to name a field in your source data that represents the date/time you want to use to filter your query"
        end
        @time_period ||= detect_time_period || :date

        if transient? && time_dimension.expression_type != :field_name
          raise "You are attempting to filter against the derived dimension (#{time_dim.name}=#{dim_time.expression}) in a transient query. This is not allowed in transient queries, which only allow filtering fields specified using :field_name"
        end

        time_filter = {}

        dim_name =  time_dimension.name
        time_filter["$gte"]=@from_date.utc.to_cubicle(@time_period) if @from_date
        time_filter["$lte"]=@to_date.utc.to_cubicle(@time_period) if @to_date
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
      if (measure.is_a?(Cubicle::Ratio))
        select measure.numerator, measure.denominator unless all_measures?
        return measure
      end

      return measure if transient?

      #when selecting from a cached map_reduce query, we no longer want to count rows, but aggregate
      #the pre-calculated counts stored in the cached collection. Therefore, any :counts become :sum
      aggregation = measure.aggregation_method == :count ? :sum : measure.aggregation_method
      expression = "this.value.#{measure.name}"
      if (aggregation == :average)
        count_field = expression + "_count"
        expression = "#{expression}*#{count_field}"
      end
      Cubicle::Measure.new(measure.name, :expression=>expression,:aggregation_method=>aggregation)
    end

  end
end
