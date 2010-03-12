module Cubicle
  class Member

    attr_accessor :name,
                  :expression,
                  :expression_type, #can be :field_name, :javascript
                  :options,
                  :alias_list

    def initialize(*args)
      opts = args.extract_options!
      @name = args.shift.to_sym

      self.options = (opts || {}).symbolize_keys

      if (@expression = self.options.delete(:field_name))
        @expression_type = :field_name
      elsif (@expression = self.options.delete(:expression))
        @expression_type = :javascript
      else
        @expression = @name
        @expression_type = :field_name
      end

      member_alias = self.options[:alias]
      if (member_alias)
        member_alias = [member_alias] unless member_alias.is_a?(Array)
        @alias_list = member_alias.map{|a|a.to_s}
      end

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

    def to_js_value
      prefix, suffix = expression_type == :field_name ? ['this.',''] : ['(',')']
      "#{prefix}#{expression}#{suffix}"
    end
  end
end
