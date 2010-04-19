class DefectCubicle
  extend Cubicle::Aggregation

  define     :preventable, "this.root_cause != 'act_of_god'"
  define     :product_name, "this.product.name"
  define     :current_year, "'{{date_today_iso}}'.substring(0,4)"

  date       :manufacture_date,  :field_name=>'manufacture_date', :alias=>:date
  dimension  :month,             :expression=>'this.manufacture_date.substring(0,7)'
  dimension  :year,              :expression=>'this.manufacture_date.substring(0,4)'

  dimension  :manufacture_time

  dimension  :product,           :expression=>'{{product_name}}'
  dimension  :region,            :field_name=>'plant.address.region'

  dimensions :operator, :outcome
  
  count :total_defects,          :field_name=>'defect_id'
  count :distinct_products,      :expression=>'{{product}}', :distinct=>true
  count :preventable_defects,    :expression=>'{{preventable}}'
  count :conditioned_preventable,:expression=>'1.0', :condition=>'{{preventable}}'
  count :defects_this_year,      :expression=>'{{year}} == {{current_year}}'
  sum   :total_cost,             :field_name=>'cost'
  avg   :avg_cost,               :field_name=>'cost'

  #calculated fields
  ratio      :preventable_pct,  :preventable_defects, :total_defects
  ratio      :distinct_ratio,   :distinct_products,   :total_defects
  difference :inevitable_defects, :total_defects, :preventable_defects
  #durations
  average_duration :ms1 => :ms2
  total_duration :ms2 => :ms3
  duration  :total_duration, :ms1 => :ms3, :in=>:days
  duration  :conditional_duration, :ms1 => :ms3, :in=>:days, :condition=>"this.defect_id != 2"
  elapsed   :ms3, :in=>:days
  age_since :avg_time_since_ms3,:ms3, :in=>:days

  #bucketized fields
  categorize :avg_cost_category,
             :avg_cost, 1..5, :bucket_size=>0.5, :range_start_bump=>0.01 do |bucket_start,bucket_end|
    if bucket_start == :begin
      '< $1'
    elsif bucket_end == :end
      '> $5'
    else
      "$#{bucket_start} - $#{bucket_end}"
    end
  end



  #pre-cached aggregations
  aggregation :month, :year, :product
  aggregation :month, :region

end