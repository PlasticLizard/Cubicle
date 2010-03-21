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
        for(var key in doc){
			if (doc[key] || doc[key] == 0){
				output[key] = output[key] || 0;
				output[key]  += doc[key];
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

     #{  (query.measures.select{|m|m.aggregation_method == :average}).map do |m|
            "value.#{m.name}=value.#{m.name}/value.#{m.name}_count;"
          end.join("\n")}
          #{  (query.measures.select{|m|m.aggregation_method == :calculation}).map do|m|
            "value.#{m.name}=#{m.expression};";
          end.join("\n")}
    return value;
    }
FINALIZE
        end
      end
    end
  end
end