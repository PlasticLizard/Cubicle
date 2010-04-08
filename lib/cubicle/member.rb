module Cubicle
  class Member

    attr_accessor :name,
                  :field_name,
                  :expression,
                  :expression_type, #can be :field_name, :javascript
                  :options,
                  :alias_list,
                  :condition

    def initialize(*args)
      opts = args.extract_options!
      @name = args.shift.to_sym if args[0].is_a?(String) or args[0].is_a?(Symbol)

      self.options = (opts || {}).symbolize_keys

      if @expression = options(:field_name)
        @expression_type = :field_name
        @field_name = @expression
      elsif @expression = options(:expression)
        @expression_type = :javascript
      else
        @expression = @name
        @field_name = @name
        @expression_type = :field_name
      end

      member_alias = options(:alias)
      if (member_alias)
        member_alias = [member_alias] unless member_alias.is_a?(Array)
        @alias_list = member_alias.map{|a|a.to_s}
      end

      @condition = options :condition_expression,:condition


    end

    def options(*args)
      return @options if args.empty?
      args.collect {|opt|found=@options.delete(opt)}.compact.pop
    end

    def matches(member_name)
      return name.to_s == member_name.to_s || (@alias_list||=[]).include?(member_name.to_s)
    end

    def included_in?(list_of_member_names)
      list_of_member_names.each do |member_name|
        return true if matches(member_name)
      end
      false
    end

    def to_js_keys
      ["#{name}:#{to_js_value}"]
    end

    def expression
      prefix, suffix = expression_type == :field_name ? ['this.',''] : ['(',')']
      "#{prefix}#{@expression}#{suffix}"
    end

    def to_js_value
      condition.blank? ? expression : "(#{condition}) ? (#{expression}) : null"
    end
  end
end
