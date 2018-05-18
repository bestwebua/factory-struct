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

    subclass = Class.new self do
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
    end

    constant.nil? ? subclass : const_set(constant, subclass)
  end

  def == (other)
    self.class == other.class && self.values == other.values
  end

  def [] (arg)
    if arg.is_a?(Integer)
      index_error = "offset #{arg} too large for factory(size:#{self.size})"
      raise IndexError, index_error unless arg.between?(0, members.size-1)
      send(members[arg])
    else
      name_error = "no member '#{arg}' in factory"
      raise NameError, name_error unless members.include?(arg)
      send(arg)
    end
  end

  def []= (arg, value)
    self[arg]
      attribute = if arg.is_a?(Integer)
        :"#{members[arg].to_s.insert(0, '@')}"
      else
        :"#{arg.to_s.insert(0, '@')}"
      end
    instance_variable_set(attribute, value)
  end

  def dig (*args)
    to_h.dig(*args)
  end

  def each (&block)
    return enum_for(:each) unless block
    members.each { |attribute| block.call(send(attribute)) }
    self
  end

  def each_pair (&block)
    return enum_for(:each) unless block
    to_h.each_pair(&block)
  end

  def eql? (other)
    self.class == other.class && (self.values).eql?(other.values)
  end

  def length
    members.size
  end

  def members
    instance_variables.map { |instance_var| :"#{instance_var.to_s.delete('@')}" }
  end

  def select (&block)
    return enum_for(:select) unless block
    values.select(&block)
  end

  def to_h
    members.zip(values).to_h
  end

  def values
    members.map { |attribute| send(attribute) }
  end

  def values_at (*args)
    args.select { |arg| arg.is_a?(Integer) }.each do |arg|
      error = case
        when arg < -values.size then "offset #{arg} too small"
        when arg > values.size-1 then "offset #{arg} too large"
      end
      raise IndexError, error + " for factory(size:#{size})" if error
    end
    values.values_at(*args)
  end

  alias :size :length
  alias :to_a :values
  alias :to_s :inspect

end
