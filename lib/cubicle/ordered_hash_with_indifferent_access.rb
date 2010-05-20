class OrderedHashWithIndifferentAccess < OrderedHash
  def initialize(initial_data={})
    merge!(initial_data.stringify_keys)
  end


  def [](key)
      key = key.to_s
      #self[key] = [] unless self.keys.include?(key)
      super(key)
    end

    def []=(key,val)
      super(key.to_s,val)
    end

    def include?(key)
      super(key.to_s)
    end

   def method_missing(sym,*args,&block)
      return self[sym.to_s[0..-2]] = args[0] if sym.to_s =~ /.*=$/
      return self[sym] if include?(sym)
      nil
    end
end