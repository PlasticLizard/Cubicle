module AnalyticsDateTimeSupport
  
  def days_in_month
    end_of_month.day
  end
  def days_in_year
    end_of_year.yday
  end
  def days_in_quarter
    end_of_quarter.yday - beginning_of_quarter.yday
  end
  def proportion_of_day_elapsed
    Time.now.hour / 24.0
  end
  def proportion_of_week_elapsed
    wday / 7.0
  end
  def proportion_of_month_elapsed
    day / days_in_month.to_f
  end
  def proportion_of_quarter_elapsed
    (yday-beginning_of_quarter.yday) / days_in_quarter.to_f
  end
  def proportion_of_year_elapsed
    yday / days_in_year.to_f
  end

  def db_date
    self.strftime('%Y-%m-%d')
  end
  alias db_day db_date

  def db_month
    self.strftime('%Y-%m')
  end

  def db_quarter
    "#{db_year}-Q#{(month+2) / 3}"
  end

  def db_year
    self.strftime('%Y')
  end

  def db_string(period = :date)
    case period
      when :year, :years then db_year
      when :quarter, :quarters then db_quarter
      when :month, :months then db_month
      else db_date
    end
  end

  def beginning_of(period)
    self.send "beginning_of_#{period.to_s.singularize}"
  end

 

end