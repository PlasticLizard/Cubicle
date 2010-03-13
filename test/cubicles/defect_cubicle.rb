class DefectCubicle
  extend Cubicle

  date       :manufacture_date,  :field_name=>'manufacture_date', :alias=>:date
  dimension  :month,             :expression=>'this.manufacture_date.substring(0,7)'
  dimension  :year,              :expression=>'this.manufacture_date.substring(0,4)'
  
  dimension  :product,           :field_name=>'product.name'
  dimension  :region,            :field_name=>'plant.address.region'
  
  dimensions :operator, :outcome
  
  count :total_defects,          :field_name=>'defect_id'
  count :preventable_defects,    :expression=>'this.root_cause != "act_of_god"'
  sum   :total_cost,             :field_name=>'cost'
  avg   :avg_cost,               :field_name=>'cost'

  #calculated fields
  ratio :preventable_pct,  :preventable_defects, :total_defects

  #pre-cached aggregations
  aggregation :month, :year, :product
  aggregation :month, :region
end