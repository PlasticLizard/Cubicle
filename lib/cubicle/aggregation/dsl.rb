module Cubicle
  module Aggregation
    module Dsl
      
      def source_collection_name(collection_name = nil)
        return @source_collection = collection_name if collection_name
        @source_collection ||= name.chomp("Cubicle").chomp("Cube").chomp("Aggregation").underscore.pluralize
      end
      alias source_collection_name= source_collection_name

      def target_collection_name(collection_name = nil)
        return nil if transient?
        return @target_name = collection_name if collection_name
        @target_name ||= "#{name.blank? ? source_collection_name : name.underscore.pluralize}_cubicle"
      end
      alias target_collection_name= target_collection_name

      def dimension(*args)
        dimensions << Cubicle::Dimension.new(*args)
        dimensions[-1]
      end      

      def dimensions(*args)
        return (@dimensions ||= Cubicle::MemberList.new) if args.length < 1
        args = args[0] if args.length == 1 && args[0].is_a?(Array)
        args.each {|dim| dimension dim }
        @dimensions
      end

      def measure(*args)
        measures << Measure.new(*args)
        measures[-1]
      end

      def measures(*args)
        return (@measures ||= Cubicle::MemberList.new) if args.length < 1
        args = args[0] if args.length == 1 && args[0].is_a?(Array)
        args.each {|m| measure m}
        @measures
      end

      def count(*args)
        options = args.extract_options!
        options[:aggregation_method] = :count
        measure(*(args << options))
      end

      def average(*args)
        options = args.extract_options!
        options[:aggregation_method] = :average
        measure(*(args << options))
        #Averaged fields need a count of non-null values to properly calculate the average
        args[0] = "#{args[0]}_count".to_sym
        count *args
      end
      alias avg average

      def sum(*args)
        options = args.extract_options!
        options[:aggregation_method] = :sum
        measure(*(args << options))
      end

      def duration(*args)
        options = args.extract_options!
        options[:in] ||= durations_in
        args << options
        measures << (dur = Duration.new(*args))
        count("#{dur.name}_count".to_sym, :expression=>dur.expression, :condition=>dur.condition) if dur.aggregation_method == :average
      end

      def average_duration(*args)
        duration(*args)
      end
      alias avg_duration average_duration

      def total_duration(*args)
        options = args.extract_options!
        options[:aggregation_method] = :sum
        duration(*(args<<options))
      end

      def duration_since(*args)
        options = args.extract_options!
        ms1 = args.length > 1 ? args.delete_at(1) : args.shift
        options[ms1] = :now
        duration(*(args<<options))
      end
      alias age_since duration_since
      alias elapsed duration_since

      def durations_in(unit_of_time = nil)
        return (@duration_unit ||= :seconds) unless unit_of_time
        @duration_unit = unit_of_time.to_s.pluralize.to_sym
      end
      alias :duration_unit :durations_in


      def ratio(member_name, numerator, denominator)
        measures << Ratio.new(member_name, numerator, denominator)
      end

      def aggregation(*member_list)
        member_list = member_list[0] if member_list[0].is_a?(Array)
        aggregations << member_list
      end

      def time_dimension(*args)
        return (@time_dimension ||= nil) unless args.length > 0
        @time_dimension = dimension(*args)
      end
      alias time_dimension= time_dimension
      alias date time_dimension
      alias time time_dimension
    end
  end
end