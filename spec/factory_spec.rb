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

  describe 'Factory::Test' do

    subject(:item) { @factory_object.new(1, 2) }

    describe '#==' do

      subject(:item1) { subject }
      subject(:item2) { @factory_object.new(1, 2.0)}
      
      it 'return true' do
        expect(item1 == subject).to eq(true)
      end

      it 'return true' do
        expect(item1 == item2).to eq(true)
      end
    end

    describe '#[]' do
      it 'factory[member] should return object' do
        expect(subject[:a]).to eq(1)
      end

      it 'should raise NameError if the member does not exist' do
        expect { subject[:c] }.to raise_error(NameError)
      end

      it 'factory[index] should return object' do
        expect(subject[1]).to eq(2)
      end

      it 'should raise IndexError if the index is out of range' do
        expect { subject[2] }.to raise_error(IndexError)
      end
    end

    describe '#[]=' do

      subject(:change_by_key)   { @factory_object.new(1, 2)[:a] = 100 }
      subject(:change_by_index) { @factory_object.new(1, 2)[1] = 200 }

      it 'factory[member]= should change value' do
        expect(change_by_key).to eq(100)
      end

      it 'should raise NameError if the member does not exist' do
        expect { item[:c] }.to raise_error(NameError)
      end

      it 'factory[index]= should change value' do
        expect(change_by_index).to eq(200)
      end

      it 'should raise IndexError if the index is out of range' do
        expect { item[2] }.to raise_error(IndexError)
      end
    end

    describe '#dig' do

      subject(:nested_object) { Factory.new(:id, :position).new(1, 'PR') }
      subject(:top_object)    { Factory.new(:company, :worker).new('SecretCompany', nested_object) }

      it 'should extract the nested value specified by the sequence of key objects' do
        expect(top_object.dig(:worker, :id)).to eq(1)
      end

      it 'should return nil if nothing to dig' do
        expect(top_object.dig(:worker, :sex)).to eq(nil)
      end

      it 'should raise_error TypeError' do
        expect { top_object.dig(:worker, :id, :some_key) }.to raise_error(TypeError)
      end
    end

    describe '#each' do
      it 'should yields the value of each factory member in order' do
        expect(subject.each.to_a).to eq([1,2])
      end

      it 'return an enumerator if no block is given' do
        expect(subject.each.class).to eq(Enumerator)
      end
    end

    describe '#each_pair' do
      it 'should yields the name and value of each factory member in order' do
        expect(subject.each_pair { |k,v| }.to_a).to eq([[:a, 1], [:b, 2]])
      end

      it 'return an enumerator if no block is given' do
        expect(subject.each_pair.class).to eq(Enumerator)
      end
    end

    describe '#eql?' do

      subject(:object) { Factory.new(:a, :b).new(1, 2) }
      subject(:same_object_with_other_values) { Factory.new(:a, :b).new(1, 2.0) }

      it 'return false if object was other type' do
        expect(subject).to_not eql(Object.new)
      end

      it 'return true if they have the same factory subclass and have equal member values' do
        expect(subject).to eql(subject)
      end

      it 'return false if objects has different values' do
        expect(object).to_not eql(same_object_with_other_values)
      end
    end

    describe '#to_s' do
      it 'should be an alias of :inspect' do
        expect(subject.method(:to_s).original_name).to eq(:inspect)
      end

      it 'return true' do
        expect(subject.to_s).to eq(subject.inspect)
      end
    end


  end

end