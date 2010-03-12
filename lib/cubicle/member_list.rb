module Cubicle
  class MemberList < Array
    def [](member_name)
      if (member_name.is_a?(Integer))
        return super(member_name)
      end
      self.find{|m|m.matches(member_name)}
    end
    #Code here
  end
end
