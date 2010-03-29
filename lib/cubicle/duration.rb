module Cubicle
  class Duration < Measure
    attr_accessor :duration_unit, :begin_milestone, :end_milestone, :timestamp_prefix

    def initialize(*args)
      super
      self.duration_unit = options(:in) || :seconds
      self.timestamp_prefix = options :timestamp_prefix, :prefix
      self.expression_type = :javascript
      #only one item should be left in the hash, the duration map
      raise "duration must be provided with a hash with a single entry, where the key represents the starting milestone of a duration and the value represents the ending milestone." if options.length != 1

      self.begin_milestone, self.end_milestone = options.to_a[0]
      self.name ||= "#{begin_milestone}_to_#{end_milestone}_#{aggregation_method}".to_sym
    end

    def default_aggregation_method
      :average
    end

    def condition
      cond = " && (#{super})" unless super.blank?
      "#{milestone_js(:begin)} && #{milestone_js(:end)}#{cond}"
    end

    def expression
      #prefix these names for the expression
#      prefix = "#{self.timestamp_prefix}#{self.timestamp_prefix.blank? ? '' : '.'}"
#      ms1,ms2 = [self.begin_milestone,self.end_milestone].map{|ms|ms.to_s=='now' ? "new Date(#{Time.now.to_i*1000})" : "this.#{prefix}#{ms}"}
      @expression = "(#{milestone_js(:end)}-#{milestone_js(:begin)})/#{denominator}" 
    end

    private

    def milestone_js(which)
     prefix = "#{self.timestamp_prefix}#{self.timestamp_prefix.blank? ? '' : '.'}"
     ms = self.send("#{which.to_s}_milestone")
     ms.to_s=='now' ? "new Date(#{Time.now.to_i*1000})" : "this.#{prefix}#{ms}"
    end

    def denominator
      #Date math results in milliseconds in javascript
      case self.duration_unit || :seconds
        when :days    then "1000/60/60/24.0"
        when :hours   then "1000/60/60.0"
        when :minutes then "1000/60.0"
        else               "1000.0"
      end
    end

  end
end