module Cubicle
  module DateTime
    def self.db_time_format
      @time_format ||= :iso8601 #or :native || :time || anything not :iso8601
    end

    def self.db_time_format=(time_format)
      raise "db_time_format must be :iso8601 or :native" unless [:iso8601,:native].include?(time_format)
      @time_format=time_format
    end

    def self.iso8601?
      self.db_time_format == :iso8601
    end

    def iso8601?
      Cubicle::DateTime.iso8601?
    end

    def to_cubicle(period = :date)
      case period
        when :year, :years then iso8601? ? self.strftime('%Y') : beginning_of_year
        when :quarter, :quarters then iso8601? ? "#{db_year}-Q#{(month+2) / 3}" : beginning_of_quarter
        when :month, :months then iso8601? ? self.strftime('%Y-%m') : beginning_of_month
        else iso8601? ? self.strftime('%Y-%m-%d') : self
      end
    end

    def beginning_of(period)
      self.send "beginning_of_#{period.to_s.singularize}"
    end
  end
end
