class String
  def is_a_const?
    [/[A-Z]{1}[a-zA-Z0-9_]+/]
  end
end

class Factory

  include Enumerable

  def self.new(*args)
    constant = args[0].is_a?(String) && args[0].is_a_const? ? args[0] : nil
    class_args = constant.nil? ? args : args[1..-1]

    case
      when args.empty?
        raise ArgumentError, 'wrong number of arguments (given 0, expected 1+)'
      when args.size > 1
        raise NameError, "wrong constant name #{constant}" if constant.nil? && class_args.empty?
        raise TypeError, "#{class_args[0]} is not a symbol nor a string" if class_args.all? { |i| !i.is_a?(Symbol) }
    end

    subclass = Class.new Factory do

      attr_accessor *class_args

      define_singleton_method(:new) do |*args|
        object = allocate
        object.send(:initialize, *args)
        object
      end

      define_method(:initialize) do |*args|
        subclass_args = Array.new(class_args.size).map.with_index { |item, index| args[index] }
        raise ArgumentError, 'factory size differs' if args.size > class_args.size
        class_args.zip(subclass_args).each { |accessor, value| public_send("#{accessor}=", value) }
      end

      define_method(:==) do |other|
        self.class == other.class && self.values == other.values
      end

      define_method(:[]) do |arg|
        if arg.is_a?(Integer)
          index_error = "offset #{arg} too large for factory(size:#{self.size})"
          raise IndexError, index_error unless arg.between?(0, attributes.size-1)
          send(attributes[arg])
        else
          name_error = "no member '#{arg}' in factory"
          raise NameError, name_error unless attributes.include?(arg)
          send(arg)
        end
      end

      define_method(:[]=) do |arg, value|
        self[arg]
        attribute = if arg.is_a?(Integer)
          attributes[arg].to_s.insert(0, '@').to_sym
        else
          arg.to_s.insert(0, '@').to_sym
        end
        instance_variable_set(attribute, value)
      end

      define_method(:dig) do |*args|
        to_h.dig(*args)
      end

      define_method(:each) do |&block|
        return enum_for(:each) unless block
        attributes.each { |attribute| block.call(send(attribute)) }
        self
      end

      define_method(:each_pair) do |&block|
        return enum_for(:each) unless block
        to_h.each_pair(&block)
      end

      define_method(:eql?) do |other|
        self.class == other.class && (self.values).eql?(other.values)
      end

      define_method(:length) do
        attributes.size
      end

      define_method(:members) do
        attributes
      end

      define_method(:select) do |&block|
        return enum_for(:select) unless block
        values.select(&block)
      end

      define_method(:to_h) do
        attributes.zip(values).to_h
      end

      define_method(:values) do
        attributes.map { |attribute| send(attribute) }
      end

      define_method(:values_at) do |from, to|
        result = values.values_at(from, to)
        error = case
            when result.first.nil? then "offset #{from} too small"
            when result.last.nil? then "offset #{to} too large"
          end
        raise IndexError, error + " for factory(size:#{size})" if result.any?(&:nil?)
        result
      end

      define_method(:attributes) do
        instance_variables.map { |instance_var| instance_var.to_s.delete('@').to_sym }
      end

      alias :size :length
      alias :to_a :values
      alias :to_s :inspect
      
      private :attributes

    end

    constant.nil? ? subclass : const_set(constant, subclass)

  end
end
