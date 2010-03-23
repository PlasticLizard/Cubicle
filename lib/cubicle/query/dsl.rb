module Cubicle
  class Query
    module Dsl
      include TimeIntelligence
      def select_all
        select :all_dimensions, :all_measures
      end

      def transient!
        @transient = true
        @source_collection_name = nil
      end

      def select(*args)
        args = unalias(args[0].is_a?(Array) ? args[0] : args)
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
            if (member = @aggregation.dimensions[member_name])
              @dimensions << convert_dimension(member)
            elsif (member = @aggregation.measures[member_name])
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
        #Resolve any query level aliases
        args = unalias(args)
        #We'll need these in the result set
        select *args
        #replace any alias names with actual member names
        @by = args.map{|member_name|@aggregation.find_member(member_name).name}
        return if @time_dimension #If a time dimension has been explicitly specified, the following isn't helpful.

        #Now let's see if we can find ourselves a time dimension
        if (@aggregation.time_dimension && time_dimension.included_in?(args))
          time_dimension(@aggregation.time_dimension)
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
          @order_by << (order.is_a?(Array) ? [unalias(order[0]),order[1]] : [unalias(order),:asc])
        end
        self
      end

      def where(filter = nil)
        return prepare_filter unless filter
        filter.each do |key,value|
          (@where ||= {})[unalias(key)] = value
        end
        self
      end

      def alias_member(alias_hash)
        alias_hash.each {|key,value|@query_aliases[value] = key}
        self
      end
      alias alias_members alias_member
    end
  end

end
