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
    self.step_by = :day if step_by.to_sym == :date
    valid_steps = [:second,:minute,:hour,:week,:day,:month,:year]
    valid_steps += valid_steps.map{|s|s.to_s.pluralize.to_sym}
    raise "Invalid 'step_by' speficication. Was #{step_by} but must be one of #{valid_steps.inspect}" unless valid_steps.include?(step_by.to_sym)

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
    self.step_by = :day if step_by.to_sym == :date
    valid_steps = [:second,:minute,:hour,:week,:day,:month,:year]
    valid_steps += valid_steps.map{|s|s.to_s.pluralize.to_sym}
    raise "Invalid 'step_by' speficication. Was #{step_by} but must be one of #{valid_steps.inspect}" unless valid_steps.include?(step_by.to_sym)

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

module Mongo
  class Connection
    def slave_lag
      args = BSON::OrderedHash.new
      args["serverStatus"] = 1
      args["repl"] = 1
      result = self["admin"].command(args)
      local_time = result["localTime"]
      sources = {}
      result["repl"]["sources"].each do |source|
        sync_time = source["syncedTo"]["time"]
        sources[source["host"]] = local_time - sync_time
      end
      sources     
    end
  end
end