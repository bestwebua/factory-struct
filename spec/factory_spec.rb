require_relative '../factory'

describe Factory do
  before(:context) do
    @factory_object = Factory.new('Test', :a, :b)
  end

  describe '.new' do
    context 'object keys' do
      let(:without_args)        { Factory.new }
      let(:with_keys)           { Factory.new(:a, :b).new }
      let(:with_wrong_keys)     { Factory.new(:a, 1) }
      let(:with_mix_keys)       { Factory.new(:a, 'b').new }
      let(:with_wrong_name)     { Factory.new('wrong_constant') }
      let(:with_name_and_keys)  { @factory_object.new }

      alias_method :without_name, :with_keys
      
      context 'factory object without name' do
        specify do
          expect(without_name.class).to be_an_instance_of(Class)
        end

        describe 'instance vars initialization' do
          shared_examples(:init_instance_vars) do
            specify { expect(instance_vars).to eq(%i[@a @b]) }
          end

          context 'with keys' do
            let(:instance_vars) { with_keys.instance_variables }
            it_behaves_like(:init_instance_vars)
          end

          context 'with mix keys' do
            let(:instance_vars) { with_mix_keys.instance_variables }
            it_behaves_like(:init_instance_vars)
          end
        end

        describe 'errors' do
          context 'ArgumentError' do
            specify do
              expect { without_args }.to raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 1+)')
            end
          end

          context 'TypeError' do
            specify do
              expect { with_wrong_keys }.to raise_error(TypeError, '1 is not a symbol nor a string')
            end
          end
        end
      end

      context 'factory object with name' do
        let(:struct_ancestors) do
          Struct.new('Test').ancestors.map { |item| eval(item.to_s.sub(/Struct/,'Factory')) }
        end

        specify do 
          expect { with_wrong_name }.to raise_error(NameError, 'identifier wrong_constant needs to be constant')
        end
        
        specify do
          expect(with_name_and_keys).to be_an_instance_of(Factory::Test)
        end

        it 'should have instance variables based by send keys' do
          expect(with_name_and_keys.instance_variables).to eq(%i[@a @b])
        end

        specify do
          expect(with_name_and_keys.class.ancestors).to eq(struct_ancestors)
        end

        it 'returns getters and setters only' do
          expect(with_name_and_keys.public_methods(all=false).sort).to eq(%i[a a= b b=])
        end
      end
    end

    describe 'object values' do
      let(:without_args)                     { @factory_object.new }
      let(:with_args_less_than_exists_vars)  { @factory_object.new(1) }
      let(:base_case)                        { @factory_object.new(1, 2) }
      let(:with_args_more_vars_by_quantity)  { @factory_object.new(1, 2, 3) }

      alias_method :with_args_equal_vars_by_quantity, :base_case

      it 'fill out all values of instance variables with nil' do
        expect(without_args.values.all?(&:nil?)).to be(true)
      end

      it 'fill out all values of instance variables with not passed args with nil' do
        expect(with_args_less_than_exists_vars.count(&:nil?)).to eq(1)
      end

      it 'fill out all values of instance variables with all args' do
        expect(with_args_equal_vars_by_quantity.size).to eq(2)
      end

      context 'passed args more than quantity of defined args' do
        specify do
          expect { with_args_more_vars_by_quantity }.to raise_error(ArgumentError, 'factory size differs')
        end
      end

      context 'instance variables values equal all passed args' do
        it 'returns true' do
          expect(base_case.values).to eq([1, 2])
        end
      end
    end

    describe 'object public methods' do
      let(:factory_methods) { Factory.instance_methods(all=false).sort.size }
      let(:struct_methods) do
        Struct.instance_methods(all=false).reject { |i| %i{pretty_print pretty_print_cycle}.include?(i) }.size
      end

      it 'equals Struct public methods' do
        expect(factory_methods).to eq(struct_methods)
      end
    end
  end

  describe 'Factory::Test' do
    subject(:item) { @factory_object.new(1, 2) }

    describe '#==' do
      let(:item1) { subject }
      let(:item2) { @factory_object.new(1, 2.0) }
      
      it 'returns true' do
        expect(item1).to eq(subject)
      end

      it 'returns true' do
        expect(item1).to eq(item2)
      end
    end

    describe '#[]' do
      it 'factory[member] returns object' do
        expect(subject[:a]).to eq(1)
      end

      it 'factory[index] returns object' do
        expect(subject[1]).to eq(2)
      end

      context 'errors' do
        context 'member does not exist' do
          specify do
            expect { subject[:c] }.to raise_error(NameError, "no member 'c' in factory")
          end
        end

        context 'index is out of range' do
          specify do
            expect { subject[2] }.to raise_error(IndexError, 'offset 2 too large for factory(size:2)')
          end
        end
      end
    end

    describe '#[]=' do
      let(:change_by_key)   { @factory_object.new(1, 2)[:a] = 100 }
      let(:change_by_index) { @factory_object.new(1, 2)[1] = 200 }

      it 'factory[member]= should change value' do
        expect(change_by_key).to eq(100)
      end

      it 'factory[index]= should change value' do
        expect(change_by_index).to eq(200)
      end

      context 'errors' do
        context 'member does not exist' do
          specify do
            expect { item[:c] }.to raise_error(NameError, "no member 'c' in factory")
          end
        end

        context 'index is out of range' do
          specify do
            expect { item[2] }.to raise_error(IndexError, 'offset 2 too large for factory(size:2)')
          end
        end
      end
    end

    describe '#dig' do
      let(:nested_object) { Factory.new(:id, :position).new(1, 'PR') }
      let(:top_object)    { Factory.new(:company, :worker).new('SecretCompany', nested_object) }

      it 'extract the nested value specified by the sequence of key objects' do
        expect(top_object.dig(:worker, :id)).to eq(1)
      end

      it 'returns nil if nothing to dig' do
        expect(top_object.dig(:worker, :sex)).to be_nil
      end

      specify do
        expect { top_object.dig(:worker, :id, :some_key) }.to raise_error(TypeError, 'Integer does not have #dig method')
      end
    end

    describe '#each' do
      it 'yields the value of each factory member in order' do
        expect(subject.each.to_a).to eq([1,2])
      end

      it 'returns an enumerator if no block is given' do
        expect(subject.each).to be_an_instance_of(Enumerator)
      end
    end

    describe '#each_pair' do
      it 'yields the name and value of each factory member in order' do
        expect(subject.each_pair { |k,v| }.to_a).to eq([[:a, 1], [:b, 2]])
      end

      it 'returns an enumerator if no block is given' do
        expect(subject.each_pair).to be_an_instance_of(Enumerator)
      end
    end

    describe 'eql methods' do
      let(:object)                        { @factory_object.new(1, 2) }
      let(:same_object_with_other_values) { @factory_object.new(1, 2.0) }

      context '#eql?' do
        it 'returns false if object was other type' do
          expect(subject).to_not eql(Object.new)
        end

        it 'returns true if they have the same factory subclass and have equal member values' do
          expect(subject).to eql(object)
        end

        it 'returns false if objects has different values' do
          expect(subject).to_not eql(same_object_with_other_values)
        end
      end

      context '#hash' do
        it 'returns true if both hashes were equal values' do
          expect(subject.hash).to eq(object.hash)
        end
      end
    end

    describe '#inspect' do
      let(:object_wihout_name)    { Factory.new(:a, :b).new(1, 2) }
      let(:object_without_values) { @factory_object.new }

      it 'returns custom inspect for object' do
        expect(subject.inspect).to eq('#<factory Factory::Test a=1, b=2>')
      end

      it 'returns custom inspect for object without name' do
        expect(object_wihout_name.inspect).to eq('#<factory  a=1, b=2>')
      end

      it 'returns custom inspect for object without values' do
        expect(object_without_values.inspect).to eq('#<factory Factory::Test a=nil, b=nil>')
      end
    end

    describe '#to_s' do
      it 'be an alias of :inspect' do
        expect(subject.method(:to_s).original_name).to eq(:inspect)
      end

      it 'returns true' do
        expect(subject.to_s).to eq(subject.inspect)
      end
    end

    describe '#length' do
      it 'returns number of factory members' do
        expect(subject.length).to eq(2)
      end
    end

    describe '#members' do
      it 'returns members for this factory as an array' do
        expect(subject.members).to be_an_instance_of(Array)
      end

      it 'equals size to quantity of instance variables' do
        expect(subject.members.size).to eq(2)
      end

      it 'all returned items of array should be a symbols' do
        expect(subject.members.all?(&:to_sym)).to be(true)
      end

      it 'returns first factory member' do
        expect(subject.members.first).to eq(:a)
      end

      it 'returns all members in default order' do
        expect(subject.members).to eq(%i[a b])
      end
    end

    describe '#select' do
      it 'returns an array' do
        expect(subject.select(&:odd?)).to be_an_instance_of(Array)
      end

      it 'returns all finded results in default order' do
        expect(subject.select(&:to_i)).to eq([1, 2])
      end

      it 'returns an enumerator if no block is given' do
        expect(subject.select).to be_an_instance_of(Enumerator)
      end
    end

    describe '#size' do
      it 'be an alias of :length' do
        expect(subject.method(:size).original_name).to eq(:length)
      end

      it 'returns true' do
        expect(subject.size).to eq(subject.length)
      end
    end

    describe '#to_a' do
      it 'be an alias of :values' do
        expect(subject.method(:to_a).original_name).to eq(:values)
      end

      it 'returns true' do
        expect(subject.to_a).to eq(subject.values)
      end

      specify do
        expect(subject.to_a).to be_an_instance_of(Array)
      end

      it 'returns all values in default order' do
        expect(subject.to_a).to eq([1, 2])
      end
    end

    describe '#to_h' do
      specify do
        expect(subject.to_h).to be_an_instance_of(Hash)
      end

      it 'include all names and values for the factory members' do
        expect(subject.to_h).to eq({a: 1, b: 2})
      end

      it 'all keys should be in default order' do
        expect(subject.to_h.keys).to eq(%i[a b])
      end
    end

    describe '#values' do
      specify do
        expect(subject.to_a).to be_an_instance_of(Array)
      end

      it 'all values for this factory should be in default order' do
        expect(subject.to_a).to eq([1, 2])
      end
    end

    describe '#values_at' do
      context 'arguments' do
        context 'numbers' do
          specify do
            expect(subject.values_at).to be_an_instance_of(Array)
          end

          specify do
            expect(subject.values_at).to be_empty
          end

          it 'returns the factory member values for each selector as an array' do
            expect(subject.values_at(0)).to eq([1])
          end

          it 'accept multiarguments' do
            expect(subject.values_at(0, 1, 0)).to eq([1, 2, 1])
          end
        end

        context 'ranges' do
          it 'accept range' do
            expect(subject.values_at(0..1)).to eq([1, 2])
          end

          it 'returns nils if the upper range is outside' do
            expect(subject.values_at(0..3)).to eq([1, 2, nil, nil])
          end

          it 'accept ranges'  do
            expect(subject.values_at(0..1, 0..3)).to eq([1, 2, 1, 2, nil, nil])
          end
        end

        context 'numbers and ranges' do
          it 'accept nubers and ranges' do
            expect(subject.values_at(1, 0..1)).to eq([2, 1, 2])
          end
        end

        context 'errors' do
          shared_examples :raise_appropriate_error do
            specify do
              expect { subject.values_at(start_index, end_index) }.to raise_error(error_class, message)
            end
          end

          let(:size_message) { "for factory(size:#{subject.size})" }

          context 'IndexError' do
            let(:error_class) { IndexError }

            context 'large offset, out of the range' do
              let(:start_index) { 0 }
              let(:end_index)   { 100 }
              let(:message)     { "offset #{end_index} too large #{size_message}" }

              it_behaves_like(:raise_appropriate_error)
            end

            context 'small offset, out of the range' do
              let(:start_index) { -10 }
              let(:end_index)   { 1 }
              let(:message)     { "offset #{start_index} too small #{size_message}" }

              it_behaves_like :raise_appropriate_error
            end

            context 'first offset if 2 offsets is out of the range' do
              let(:start_index) { -10 }
              let(:end_index)   { 100 }
              let(:message)     { "offset #{start_index} too small #{size_message}" }

              it_behaves_like :raise_appropriate_error
            end

            context 'raises IndexError first' do
              let(:start_index) { -10..0 }
              let(:end_index)   { -100 }
              let(:message)     { "offset #{end_index} too small #{size_message}" }

              it_behaves_like :raise_appropriate_error
            end
          end

          context 'RangeError' do
            let(:error_class) { RangeError }

            context 'first range value was out of range' do
              let(:start_index) { -10..0 }
              let(:end_index) { 0 }
              let(:message) { "#{start_index} out of range" }

              it_behaves_like :raise_appropriate_error
            end
          end
        end
      end
    end
  end
end
