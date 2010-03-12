require "analytics_date_time_support"

ISO_8601_REGEX = /^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s](([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)?(\16([0-5]\d))?(\.\d+)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/

class String
  def is_iso_8601
    return true if self =~ ISO_8601_REGEX
    false
  end

  def to_date_time_hash
    pieces = self.split("T")
    {:date=>pieces[0],:time=>pieces[1]}
  end
end

class Hash
  def normalize_for_storage(opts={})
    opts = {:hashify_times=>true}.merge(opts)
    new_hash = {}
    self.each do |k,v|
      v = v.normalize_for_storage if v.is_a? Hash
      v = v.to_date_time_hash if (v.is_a?(String) && v.is_iso_8601 && opts[:hashify_times])
      v = v.to_f if (v.is_a?(String) && v =~ /^\d*\.\d+$/)
      new_hash[k.underscore] = v
    end
    new_hash
  end
end

#We are storing date/times in iso 8601 compliant strings
class Time
  include AnalyticsDateTimeSupport

  #support date ranges that can iterate by day, month, etc.
   #iteration
  def step_by
    @step_by ||= :second
  end

  def step_by=(by)
    @step_by = by
  end

  def succ
    next_date = advance(step_by.to_s.pluralize.to_sym=>1)
    next_date.step_by = self.step_by
    next_date
  end
end

class Date
  include AnalyticsDateTimeSupport
  #support date ranges that can iterate by day, month, etc.
   #iteration
  def step_by
    @step_by ||= :day
  end

  def step_by=(by)
    @step_by = by
  end

  def succ
    next_date = advance(step_by.to_s.pluralize.to_sym=>1)
    next_date.step_by = self.step_by
    next_date
  end
end

class Range
  def by!(step_by)
    first.step_by = step_by if first.respond_to?(:step_by=)
    self
  end
end

class Numeric
  def prorate(options = {})
    as_of_date = (options[:as_of] || Time.now).to_time
    period = options[:period] || :month
    multiplier = as_of_date.send("proportion_of_#{period}_elapsed".to_sym)
    multiplier * self
  end

  def project(options= {})
    current_date = (options[:as_of] || Time.now).to_time
    period = options[:period] || :month
    denominator = current_date.send("proportion_of_#{period}_elapsed".to_sym)
    self / denominator
  end
end
