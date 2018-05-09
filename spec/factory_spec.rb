require_relative '../factory'

describe Factory do
  before(:context) do
    @factory_object = Factory.new('Test', :a, :b)
  end

  describe '.new' do

    subject(:without_args)    { Factory.new }
    subject(:without_name)    { Factory.new(:a, :b).new }
    subject(:with_wrong_name) { Factory.new('wrong_constant') }
    subject(:with_right_name) { Factory.new('Name').new }
    subject(:with_wrong_keys) { Factory.new(:a, 1) }
    subject(:with_keys)       { Factory.new(:a, :b).new }
    subject(:with_mix_keys)   { Factory.new(:a, 'b').new }
    subject(:with_name_keys)  { @factory_object.new }

    it 'should raise an ArgumentError error if arguments not passed' do
      expect { without_args }.to raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 1+)')
    end

    it 'should be an instance of Class' do
      expect(without_name.class).to be_an_instance_of(Class)
    end

    it 'should have instance variables based by send keys' do
      expect(without_name.instance_variables).to eq([:@a, :@b])
    end

    it 'should raise NameError error' do
      expect { with_wrong_name }.to raise_error(NameError, 'wrong constant name wrong_constant')
    end

    it 'should be an instance of Factory::Test' do
      expect(with_right_name).to be_an_instance_of(Factory::Name)
    end

    it 'should raise TypeError error' do
      expect { with_wrong_keys }.to raise_error(TypeError, '1 is not a symbol nor a string')
    end

    it 'should have instance variables based by send keys' do
      expect(with_keys.instance_variables).to eq([:@a, :@b])
    end

    it 'should have instance variables based by send keys' do
      expect(with_mix_keys.instance_variables).to eq([:@a, :@b])
    end

    it 'should be an instance of Factory::Test' do
      expect(with_name_keys).to be_an_instance_of(Factory::Test)
    end

    it 'should have instance variables based by send keys' do
      expect(with_name_keys.instance_variables).to eq([:@a, :@b])
    end

    describe 'Factory::Test.new' do

      subject(:without_args)                     { @factory_object.new.values.all?(&:nil?) }
      subject(:with_args_less_than_exists_vars)  { @factory_object.new(1).count(&:nil?) }
      subject(:base_case)                        { @factory_object.new(1, 2).values }
      subject(:with_args_equal_vars_by_quantity) { base_case.size }
      subject(:with_args_more_vars_by_quantity)  { @factory_object.new(1, 2, 3) }


      it 'should fill out all values of instance variables with nil' do
        expect(without_args).to eq(true)
      end

      it 'should fill out all values of instance variables with not passed args with nil' do
        expect(with_args_less_than_exists_vars).to eq(1)
      end

      it 'should fill out all values of instance variables with all args' do
        expect(with_args_equal_vars_by_quantity).to eq(2)
      end

      it 'return ArgumentError if quantity of passed args was more than instance variables quantity' do
        expect { with_args_more_vars_by_quantity }.to raise_error(ArgumentError, 'factory size differs')
      end

      it 'return true if instance variables values equal all passed args' do
        expect(base_case).to eq([1, 2])
      end
    end
  end

end