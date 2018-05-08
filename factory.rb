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

      define_method(:[]) do |arg|
        arg.is_a?(Fixnum) ? send(attributes[arg]) : send(arg)
      end

      define_method(:[]=) do |attribute, value|
        instance_variable_set(attribute.to_s.insert(0, '@').to_sym, value)
      end

      define_method(:each) do |&block|
        return enum_for(:each) unless block
        attributes { |attribute| block.call(send(attribute)) }
      end

      define_method(:each_pair) do |&block|
        return enum_for(:each) unless block
        attributes.each { |attribute| block.call(attribute, send(attribute)) }
      end

      define_method(:eql?) do |other|
        self.class == other.class && (self.values).eql?(other.values)
      end

      define_method(:length) do
        attributes.size
      end

      define_method(:members) do
        attributes.map(&:to_sym)
      end

      define_method(:select) do |&block|
        return enum_for(:select) unless block
        values.select(&block)
      end

      define_method(:to_h) do
        attributes.map(&:to_sym).zip(values).to_h
      end

      define_method(:values) do
        attributes.map { |attribute| send(attribute) }
      end

      define_method(:attributes) do
        instance_variables.map { |instance_var| instance_var.to_s.delete('@') }
      end

      alias :size :length
      alias :to_a :values
      
      private :attributes

    end

    constant.nil? ? subclass : const_set(constant, subclass)

  end
end
