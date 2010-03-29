class DefectCubicle
  extend Cubicle::Aggregation

  date       :manufacture_date,  :field_name=>'manufacture_date', :alias=>:date
  dimension  :month,             :expression=>'this.manufacture_date.substring(0,7)'
  dimension  :year,              :expression=>'this.manufacture_date.substring(0,4)'

  dimension  :manufacture_time

  dimension  :product,           :field_name=>'product.name'
  dimension  :region,            :field_name=>'plant.address.region'

  dimensions :operator, :outcome

  count :total_defects,          :field_name=>'defect_id'
  count :preventable_defects,    :expression=>'this.root_cause != "act_of_god"'
  sum   :total_cost,             :field_name=>'cost'
  avg   :avg_cost,               :field_name=>'cost'

  #calculated fields
  ratio :preventable_pct,  :preventable_defects, :total_defects

  #durations
  average_duration :ms1 => :ms2
  total_duration :ms2 => :ms3
  duration  :total_duration, :ms1 => :ms3, :in=>:days
  duration  :conditional_duration, :ms1 => :ms3, :in=>:days, :condition=>"this.defect_id != 2"
  elapsed   :ms3, :in=>:days
  age_since :avg_time_since_ms3, :ms3, :in=>:days

  #pre-cached aggregations
  aggregation :month, :year, :product
  aggregation :month, :region
end