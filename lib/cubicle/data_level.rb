module Cubicle
  class DataLevel < OrderedHash

    def initialize(name = "Unknown Level", initial_data = {})
      @name = name
      merge!(initial_data.stringify_keys)
    end

    attr_reader :name
    attr_accessor :missing_member_default

    alias member_names keys

    def [](key)
      key = key.to_s
      self[key] = [] unless self.keys.include?(key)
      super(key)
    end

    def []=(key,val)
      super(key.to_s,val)
    end

    def include?(key)
      super(key.to_s)
    end

    def flatten(member_name = nil, opts={}, &block)

      default_val = opts[:default] || @missing_member_default || 0

      self.inject([]) do |output, (key, data)|
        data.inject(output) do |flattened, value|
          value.missing_member_default = default_val if value.respond_to?(:missing_member_default)

          if block_given?
            flat_val = block.arity == 1 ? (yield value) : (value.instance_eval(&block))
          end
          flat_val ||= value[member_name] if member_name && value.include?(member_name)
          flat_val ||= default_val
          flattened << flat_val
        end
      end

    end

    def leaf_level?
      return self.length < 1 ||
              !self[self.keys[0]].is_a?(Cubicle::DataLevel)
    end

    def method_missing(sym,*args,&block)
      return self[sym.to_s[0..-2]] = args[0] if sym.to_s =~ /.*=$/
      return self[sym] if self.keys.include?(sym.to_s)
      missing_member_default
    end


  end
end
