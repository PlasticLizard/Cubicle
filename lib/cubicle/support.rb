class Time
  include Cubicle::DateTime

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
  include Cubicle::DateTime
  
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