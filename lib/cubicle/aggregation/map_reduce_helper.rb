module Cubicle
  module Aggregation
    class MapReduceHelper
      class << self

        def generate_keys_string(query)
          "{#{query.dimensions.map{|dim|dim.to_js_keys}.flatten.join(", ")}}"
        end

        def generate_values_string(query)
          "{#{query.measures.map{|measure|measure.to_js_keys}.flatten.join(", ")}}"
        end

        def generate_map_function(query)
          <<MAP
    function(){emit(#{generate_keys_string(query)},#{generate_values_string(query)});}
MAP
        end

        def generate_reduce_function()
          <<REDUCE
  function(key,values){
	var output = {};
	values.forEach(function(doc){
        for(var measure_name in doc){
            var measure_value = doc[measure_name];
            if (measure_value || measure_value == 0){
                if (typeof(measure_value) == "number") {
                  output[measure_name] = output[measure_name] || 0;
                  output[measure_name] += measure_value;
                }
                else if (measure_value) {
                  output[measure_name] = output[measure_name] || {}
                  if (typeof(measure_value)=="string")
                    output[measure_name][measure_value] = true;
                  if (typeof(measure_value)=="object") {
                    for (var unique in measure_value){
                      if (typeof(unique)=="string"){output[measure_name][unique]=true;}
                    }
                  }

                }
			}
		}
	  });     
	  return output;
  }
REDUCE
        end

        def generate_finalize_function(query)
          <<FINALIZE
    function(key,value)
    {

          #{(query.measures.select{|m|m.aggregation_method == :average}).map do |m|
            "value.#{m.name}=value.#{m.name}/value.#{m.name}_count;"
          end.join("\n")}




    return value;
    }
FINALIZE
        end
      end
    end
  end
end