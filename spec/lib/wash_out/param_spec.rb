#encoding:utf-8

require 'spec_helper'

describe WashOut::Param do

  context "custom types" do

    class Abraka1 < WashOut::Type
      map(
        :test => :string
      )
    end

    class Abraka2 < WashOut::Type
      type_name 'test'
      map :foo => Abraka1
    end

    it "loads custom_types" do
      soap_config = WashOut::SoapConfig.new({ camelize_wsdl: false })
      map = WashOut::Param.parse_def soap_config, Abraka2

      expect(map).to be_a_kind_of(Array)
      expect(map[0].name).to eq 'foo'
      expect(map[0].map[0].name).to eq 'test'
    end

    it "respects camelization setting" do
      soap_config = WashOut::SoapConfig.new({ camelize_wsdl: true })

      map = WashOut::Param.parse_def soap_config, Abraka2

      expect(map).to be_a_kind_of(Array)
      expect(map[0].name).to eq 'Foo'
      expect(map[0].map[0].name).to eq 'Test'
    end
  end

  it "should accept nested empty arrays" do
    soap_config = WashOut::SoapConfig.new({ camelize_wsdl: false })
    map = WashOut::Param.parse_def(soap_config, {:nested => {:some_attr => :string, :empty => [:integer] }} )
    expect(map[0].load( {:nested => nil}, :nested)).to eq({})
  end

  describe "booleans" do
    let(:soap_config) { WashOut::SoapConfig.new({ camelize_wsdl: false }) }
    # following http://www.w3.org/TR/xmlschema-2/#boolean, only true, false, 0 and 1 are allowed.
    # Nori maps the strings true and false to TrueClass and FalseClass, but not 0 and 1.
    let(:map) { WashOut::Param.parse_def(soap_config, :value => :boolean) }

    it "should accept 'true' and '1'" do
      expect(map[0].load({:value => true}, :value)).to be true
      expect(map[0].load({:value => "1"}, :value)).to be true
    end

    it "should accept 'false' and '0'" do
      expect(map[0].load({:value => false}, :value)).to be false
      expect(map[0].load({:value => "0"}, :value)).to be false
    end
  end

  describe 'longs' do
    let(:soap_config) { WashOut::SoapConfig.new({ camelize_wsdl: false }) }
    let(:map) { WashOut::Param.parse_def(soap_config, :value => :long) }

    it "should accept positive long" do
      expect(map[0].load({:value => 9223372036854775807}, :value)).to eq 9223372036854775807
    end

    it "should accept negative long" do
      expect(map[0].load({:value => -9223372036854775807}, :value)).to eq -9223372036854775807
    end
  end

  describe '#flat_copy' do
    it 'should copy everything' do
      soap_config = WashOut::SoapConfig.new({})
      type = :foo
      multiplied = "of course"

      param = WashOut::Param.new(soap_config, 'name', type, multiplied)
      param.source_class = "middle class"
      evil_clone = param.flat_copy

      expect(evil_clone.source_class).to eq "middle class"
      expect(evil_clone.name).to eq 'name'
      expect(evil_clone.raw_name).to eq 'name'
      expect(evil_clone.type).to eq "foo"
      expect(evil_clone.multiplied).to eq "of course"
      expect(evil_clone.soap_config).to eq soap_config
    end
  end
end
