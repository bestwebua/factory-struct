class String
  def is_a_const?
    [/[A-Z]{1}[a-zA-Z0-9_]+/]
  end
end

class Factory

  def self.new(*args)
    constant = args[0].is_a?(String) && args[0].is_a_const? ? args[0] : nil
    class_args = constant.nil? ? args : args[1..-1]

    case
      when args.empty?
        raise ArgumentError, 'wrong number of arguments (given 0, expected 1+)'
      when args.size > 1
        raise NameError, "identifier #{constant} needs to be constant" if constant.nil? && class_args.empty?
        raise TypeError, "#{class_args[0]} is not a symbol" if class_args.all? { |i| !i.is_a?(Symbol) }
    end

    subclass = Class.new do
      include Enumerable
      attr_accessor *class_args

      define_method(:initialize) do |*args|
        subclass_args = Array.new(class_args.size).map.with_index { |item, index| args[index] }
        raise ArgumentError, 'factory size differs' if args.size > class_args.size
        class_args.zip(subclass_args).each { |accessor, value| public_send("#{accessor}=", value) }
      end

      define_method(:==) do |other|
        self.class == other.class && self.values == other.values
      end

      define_method(:each) do |&block|
        return enum_for(:each) unless block

        instance_variables.each do |accessor|
          block.call(instance_variable_get(accessor))
        end
      end

      define_method(:each_pair) do |&block|
        return enum_for(:each) unless block

        accessor_value = instance_variables.map do |accessor|
          [accessor.to_s.delete('@'), instance_variable_get(accessor)]
        end

        accessor_value.each do |accessor, value|
          block.call(accessor, value)
        end
      end

    end

    constant.nil? ? subclass : const_set(constant, subclass)

  end
end


=begin

      define_method(:each_pair) do |&block|
        return enum_for(:each) unless block
        
        .each do |accessor, value|
          block.call(accessor, value)
        end
      end

=end