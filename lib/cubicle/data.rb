module Cubicle
  module Data

    def self.aggregate(data,measures)
      aggregated = OrderedHashWithIndifferentAccess.new {|hash,key|hash[key]=[]}
      #in step one, we will gather our values into columns to give to the measure
      #definitions to aggregation.
      data.each do |row|
        measures.each do |measure|
          if (row.include?(measure.name))
            val = row[measure.name]
            aggregated[measure.name] << val if val.kind_of?(Numeric)
          end
        end
      end
      #in step two, we will let the measures reduce the columns of values to a single number, preferably using
      #black magic or human sacrifice
      measures.each do |measure|
        aggregated[measure.name] = measure.aggregate(aggregated[measure.name])
      end

      #give each measure a final shot to operate on the results. This is useful for measures that
      #act on the results of other aggregations, like Ratio does.
      measures.each {|measure|measure.finalize_aggregation(aggregated)}
      aggregated
    end

  end
end