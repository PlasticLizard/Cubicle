class DefectAuditCubicle
  extend Cubicle::Aggregation

  source_collection "defects"
  expand :audits, :index_variable=>'audit_index',
                  :value_variable=>'audit'

  dimension  :product,           :field_name=>'product.name'

  dimension :auditor,            :expression=>'audit.auditor'

  avg       :average_score,      :expression=>'audit.score'

end