class HashPipeCubicle
  extend Cubicle::Aggregation

  source_collection "defects"
  expand :hash_pipes

  define :score, '(hash_pipe_value.vote == "no" ? -1 : 1) * hash_pipe_value.weight'

  dimension  :product,           :field_name=>'product.name'

  dimension :hash_key,           :expression=>'hash_pipe_key'

  sum       :total_score,        :expression=>'{{score}}'


end