class String
  def is_a_const?
    [/[A-Z]{1}[a-zA-Z0-9_]+/]
  end
end

class Factory
  include Enumerable

  def self.new(*args, &block)
    constant, class_args = args[0], args[1..-1]

    case
      when args.empty?
        raise ArgumentError, 'wrong number of arguments (given 0, expected 1+)'
      when constant.nil? && !constant.is_a?(String) && !constant.is_a_const?
        raise NameError, "identifier #{constant} needs to be constant"
      when !class_args.empty? && class_args.all? { |item| !item.is_a?(Symbol) }
        raise TypeError, "#{class_args[0]} is not a symbol"
    end

    subclass = Class.new do # need to add inheritance from Factory class, exception method .new
      attr_accessor *class_args

      define_method :initialize do |*args|
        subclass_args = Array.new(class_args.size).map.with_index { |item, index| args[index] }
        raise ArgumentError, 'factory size differs' if args.size > class_args.size
        class_args.zip(subclass_args).each { |accessor, value| public_send("#{accessor}=", value) }
      end
    end

    constant.nil? ? subclass : const_set(constant, subclass)
  end

end
