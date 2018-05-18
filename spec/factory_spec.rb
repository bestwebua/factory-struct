require_relative '../factory'

describe Factory do
  before(:context) do
    @factory_object = Factory.new('Test', :a, :b)
  end

  describe '.new' do

    context 'object keys' do

      let(:without_args)        { Factory.new }
      let(:without_name)        { Factory.new(:a, :b).new }
      let(:with_wrong_keys)     { Factory.new(:a, 1) }
      let(:with_keys)           { Factory.new(:a, :b).new }
      let(:with_mix_keys)       { Factory.new(:a, 'b').new }
      let(:with_wrong_name)     { Factory.new('wrong_constant') }
      let(:with_name_and_keys)  { @factory_object.new }
      
      context 'factory object without name' do
        it 'should raise an ArgumentError error if arguments not passed' do
          expect { without_args }.to raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 1+)')
        end

        it 'should be an instance of Class' do
          expect(without_name.class).to be_an_instance_of(Class)
        end

        it 'should have instance variables based by send keys' do
          expect(without_name.instance_variables).to eq(%i[@a @b])
        end

        it 'should raise TypeError error' do
          expect { with_wrong_keys }.to raise_error(TypeError, '1 is not a symbol nor a string')
        end

        it 'should have instance variables based by send keys' do
          expect(with_keys.instance_variables).to eq(%i[@a @b])
        end

        it 'should have instance variables based by send keys' do
          expect(with_mix_keys.instance_variables).to eq(%i[@a @b])
        end
      end

      context 'factory object with name' do
        it 'should raise NameError error' do
          expect { with_wrong_name }.to raise_error(NameError, 'wrong constant name wrong_constant')
        end

        it 'should be an instance of Factory::Test' do
          expect(with_name_and_keys).to be_an_instance_of(Factory::Test)
        end

        it 'should have instance variables based by send keys' do
          expect(with_name_and_keys.instance_variables).to eq(%i[@a @b])
        end

        it 'should have ancestors like Struct' do
          expect(with_name_and_keys.class.ancestors).to eq([Factory::Test, Factory, Enumerable, Object, Kernel, BasicObject])
        end

        it 'should return getters and setters only' do
          expect(with_name_and_keys.public_methods(all=false).sort).to eq(%i[a a= b b=])
        end
      end
    end

    describe 'object values' do

      let(:without_args)                     { @factory_object.new.values.all?(&:nil?) }
      let(:with_args_less_than_exists_vars)  { @factory_object.new(1).count(&:nil?) }
      let(:base_case)                        { @factory_object.new(1, 2).values }
      let(:with_args_equal_vars_by_quantity) { base_case.size }
      let(:with_args_more_vars_by_quantity)  { @factory_object.new(1, 2, 3) }

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

      let(:item1) { subject }
      let(:item2) { @factory_object.new(1, 2.0)}
      
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
        expect { subject[:c] }.to raise_error(NameError, "no member 'c' in factory")
      end

      it 'factory[index] should return object' do
        expect(subject[1]).to eq(2)
      end

      it 'should raise IndexError if the index is out of range' do
        expect { subject[2] }.to raise_error(IndexError, 'offset 2 too large for factory(size:2)')
      end
    end

    describe '#[]=' do

      let(:change_by_key)   { @factory_object.new(1, 2)[:a] = 100 }
      let(:change_by_index) { @factory_object.new(1, 2)[1] = 200 }

      it 'factory[member]= should change value' do
        expect(change_by_key).to eq(100)
      end

      it 'should raise NameError if the member does not exist' do
        expect { item[:c] }.to raise_error(NameError, "no member 'c' in factory")
      end

      it 'factory[index]= should change value' do
        expect(change_by_index).to eq(200)
      end

      it 'should raise IndexError if the index is out of range' do
        expect { item[2] }.to raise_error(IndexError, 'offset 2 too large for factory(size:2)')
      end
    end

    describe '#dig' do

      let(:nested_object) { Factory.new(:id, :position).new(1, 'PR') }
      let(:top_object)    { Factory.new(:company, :worker).new('SecretCompany', nested_object) }

      it 'should extract the nested value specified by the sequence of key objects' do
        expect(top_object.dig(:worker, :id)).to eq(1)
      end

      it 'should return nil if nothing to dig' do
        expect(top_object.dig(:worker, :sex)).to be_nil
      end

      it 'should raise_error TypeError' do
        expect { top_object.dig(:worker, :id, :some_key) }.to raise_error(TypeError, 'Integer does not have #dig method')
      end
    end

    describe '#each' do
      it 'should yields the value of each factory member in order' do
        expect(subject.each.to_a).to eq([1,2])
      end

      it 'return an enumerator if no block is given' do
        expect(subject.each).to be_an_instance_of(Enumerator)
      end
    end

    describe '#each_pair' do
      it 'should yields the name and value of each factory member in order' do
        expect(subject.each_pair { |k,v| }.to_a).to eq([[:a, 1], [:b, 2]])
      end

      it 'return an enumerator if no block is given' do
        expect(subject.each_pair).to be_an_instance_of(Enumerator)
      end
    end

    describe 'eql methods' do

      let(:object)                        { @factory_object.new(1, 2) }
      let(:same_object_with_other_values) { @factory_object.new(1, 2.0) }

      context '#eql?' do
        it 'return false if object was other type' do
          expect(subject).to_not eql(Object.new)
        end

        it 'return true if they have the same factory subclass and have equal member values' do
          expect(subject).to eql(object)
        end

        it 'return false if objects has different values' do
          expect(subject).to_not eql(same_object_with_other_values)
        end
      end

      context '#hash' do
        it 'return true if both hashes was equal' do
          expect(subject.hash).to eq(object.hash)
        end
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

    describe '#length' do
      it 'should return number of factory members' do
        expect(subject.length).to eq(2)
      end
    end

    describe '#members' do
      it 'should return members for this factory as an array' do
        expect(subject.members).to be_an_instance_of(Array)
      end

      it 'should equal size to quantity of instance variables' do
        expect(subject.members.size).to eq(2)
      end

      it 'all return items of array should be a symbols' do
        expect(subject.members.all?(&:to_sym)).to eq(true)
      end

      it 'should return first factory member' do
        expect(subject.members.first).to eq(:a)
      end

      it 'should return all members in default order' do
        expect(subject.members).to eq(%i[a b])
      end
    end

    describe '#select' do
      it 'should return an array' do
        expect(subject.select(&:odd?)).to be_an_instance_of(Array)
      end

      it 'should return all finded results in default order' do
        expect(subject.select(&:to_i)).to eq([1, 2])
      end

      it 'return an enumerator if no block is given' do
        expect(subject.select).to be_an_instance_of(Enumerator)
      end
    end

    describe '#size' do
      it 'should be an alias of :length' do
        expect(subject.method(:size).original_name).to eq(:length)
      end

      it 'return true' do
        expect(subject.size).to eq(subject.length)
      end
    end

    describe '#to_a' do
      it 'should be an alias of :values' do
        expect(subject.method(:to_a).original_name).to eq(:values)
      end

      it 'return true' do
        expect(subject.to_a).to eq(subject.values)
      end

      it 'should return the values for this factory as an array' do
        expect(subject.to_a).to be_an_instance_of(Array)
      end

      it 'should return all values in default order' do
        expect(subject.to_a).to eq([1, 2])
      end
    end

    describe '#to_h' do
      it 'should return hash' do
        expect(subject.to_h).to be_an_instance_of(Hash)
      end

      it 'should include all names and values for the factory members' do
        expect(subject.to_h).to eq({a: 1, b: 2})
      end

      it 'all keys should be in default order' do
        expect(subject.to_h.keys).to eq(%i[a b])
      end
    end

    describe '#values' do
      it 'should return an array' do
        expect(subject.to_a).to be_an_instance_of(Array)
      end

      it 'all values for this factory should be in default order' do
        expect(subject.to_a).to eq([1, 2])
      end
    end

    describe '#values_at' do
      context 'arguments' do
        context 'nubers' do
          it 'should be an array' do
            expect(subject.values_at).to be_an_instance_of(Array)
          end

          it 'return an empty array' do
            expect(subject.values_at.empty?).to eq(true)
          end

          it 'should return the factory member values for each selector as an array' do
            expect(subject.values_at(0)).to eq([1])
          end

          it 'should accept multiarguments' do
            expect(subject.values_at(0, 1, 0)).to eq([1, 2, 1])
          end
        end

        context 'ranges' do
          it 'should accept range' do
            expect(subject.values_at(0..1)).to eq([1, 2])
          end

          it 'should return nils if the upper range is outside' do
            expect(subject.values_at(0..3)).to eq([1, 2, nil, nil])
          end

          it 'should accept ranges'  do
            expect(subject.values_at(0..1, 0..3)).to eq([1, 2, 1, 2, nil, nil])
          end
        end

        context 'numbers and ranges' do
          it 'should accept nubers and ranges' do
            expect(subject.values_at(1, 0..1)).to eq([2, 1, 2])
          end
        end
      end

      context 'errors' do
        it 'should raise IndexError if offset out of the range' do
          expect { subject.values_at(0, 100) }.to raise_error(IndexError, 'offset 100 too large for factory(size:2)')
        end

        it 'should raise IndexError if offset out of the range' do
          expect { subject.values_at(-10, 1) }.to raise_error(IndexError, 'offset -10 too small for factory(size:2)')
        end

        it 'should raise IndexError with info about first offset if 2 offsets is out of the range' do
          expect { subject.values_at(-10, 100) }.to raise_error(IndexError, 'offset -10 too small for factory(size:2)')
        end

        it 'should raise RangeError if first range value was out of range' do
          expect { subject.values_at(-10..0) }.to raise_error(RangeError, '-10..0 out of range')
        end

        it 'should raise IndexError first' do
          expect { subject.values_at(-10..0, -100) }.to raise_error(IndexError, 'offset -100 too small for factory(size:2)')
        end
      end
    end
  end
end
