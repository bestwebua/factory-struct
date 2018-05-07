class String
  def is_a_const?
    [/[A-Z]{1}[a-zA-Z0-9_]+/]
  end
end

class Factory
  include Enumerable

  def self.new(*args)
    constant, params = args[0], args[1..-1]

    case
      when args.empty?
        raise ArgumentError, 'wrong number of arguments (given 0, expected 1+)'
      when constant.nil? && !constant.is_a?(String) && !constant.is_a_const?
        raise NameError, "identifier #{constant} needs to be constant"
      when !params.empty? && params.all? { |item| !item.is_a?(Symbol) }
        raise TypeError, "#{params[0]} is not a symbol"
    end

      temp_class = Class.new Factory do

      end

    constant.nil? ? temp_class : const_set(constant, temp_class)
  end

end
