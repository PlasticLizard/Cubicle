module Cubicle
  class Expansion < Member
    attr_reader :index_variable, :value_variable
    def initialize(*args)
      super
      @index_variable = self.options[:index] ||
                        self.options[:index_variable] ||
                        self.options[:key] ||
                        self.options[:key_variable] ||
                        "#{self.name}_key"

      @value_variable = self.options[:value] ||
                        self.options[:value_variable] ||
                        "#{self.name}_value"
    end
  end
end