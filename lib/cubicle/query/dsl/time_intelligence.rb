module Cubicle
  class Query
    module Dsl
      module TimeIntelligence
        def time_range(date_range = nil)
          return nil unless date_range || @from_date || @to_date
          unless date_range
            start,stop = @from_date || Time.now, @to_date || Time.now
            return @to_date_filter=="$lte" ? start..stop : start...stop
          end

          @to_date_filter = date_range.exclude_end? ? "$lt" : "$lte"
          @from_date, @to_date = date_range.first, date_range.last if date_range
        end

        def time_dimension(dimension = nil)
          return (@time_dimension ||= @aggregation.time_dimension) unless dimension
          @time_dimension = dimension.is_a?(Cubicle::Dimension) ? dimension : @aggregation.dimensions[unalias(dimension)]
          raise "No dimension matching the name #{unalias(dimension)} could be found in the underlying data source" unless @time_dimension
          #select @time_dimension unless selected?(dimension)
        end
        alias date_dimension time_dimension

        def last(duration,as_of = Time.now)
          duration = 1.send(duration) if [:year,:month,:week,:day].include?(duration)
          period = duration.parts[0][0]
          @from_date = duration.ago(as_of).advance(period=>1)
          @to_date = as_of
        end
        alias for_the_last last

        def last_complete(duration,as_of = Time.now)
          duration = 1.send(duration) if [:year,:month,:week,:day].include?(duration)
          period = duration.parts[0][0]
          @to_date = as_of.beginning_of(period)
          @from_date = duration.ago(@to_date)
          @to_date_filter = "$lt"
        end
        alias for_the_last_complete last_complete

        def next(duration,as_of = Time.now)
          duration = 1.send(duration) if [:year,:month,:week,:day].include?(duration)
          period = duration.parts[0][0]
          @to_date = duration.from_now(as_of).advance(period=>-1)
          @from_date = as_of
        end
        alias for_the_next next

        def this(period,as_of = Time.now)
          @from_date = as_of.beginning_of(period)
          @to_date = as_of
          self
        end

        def from(time = nil)
          return @from_date unless time
          @from_date = if time.is_a?(Symbol)
            Time.send(time) if Time.respond_to?(time)
            Date.send(time).to_time if Date.respond_to?(time)
          else
            time.to_time
          end
          self
        end

        def until(time = nil)
          return @to_date unless time
          @to_date = if time.is_a?(Symbol)
            Time.send(time) if Time.respond_to?(time)
            Date.send(time).to_time if Date.respond_to?(time)
          else
            time.to_time
          end
          self
        end

        def ytd(as_of = Time.now)
          this :year, as_of
        end
        alias year_to_date ytd

        def mtd(as_of = Time.now)
          this :month, as_of
        end
        alias month_to_date mtd
      end
    end
  end
end