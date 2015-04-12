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

      map.should be_a_kind_of(Array)
      map[0].name.should == 'foo'
      map[0].map[0].name.should == 'test'
    end

    it "respects camelization setting" do
      soap_config = WashOut::SoapConfig.new({ camelize_wsdl: true })

      map = WashOut::Param.parse_def soap_config, Abraka2

      map.should be_a_kind_of(Array)
      map[0].name.should == 'Foo'
      map[0].map[0].name.should == 'Test'
    end
  end

  it "should accept nested empty arrays" do
    soap_config = WashOut::SoapConfig.new({ camelize_wsdl: false })
    map = WashOut::Param.parse_def(soap_config, {:nested => {:some_attr => :string, :empty => [:integer] }} )
    map[0].load( {:nested => nil}, :nested).should == {}
  end

  describe "booleans" do
    let(:soap_config) { WashOut::SoapConfig.new({ camelize_wsdl: false }) }
    # following http://www.w3.org/TR/xmlschema-2/#boolean, only true, false, 0 and 1 are allowed.
    # Nori maps the strings true and false to TrueClass and FalseClass, but not 0 and 1.
    let(:map) { WashOut::Param.parse_def(soap_config, :value => :boolean) }

    it "should accept 'true' and '1'" do
      map[0].load({:value => true}, :value).should be true
      map[0].load({:value => "1"}, :value).should be true
    end

    it "should accept 'false' and '0'" do
      map[0].load({:value => false}, :value).should be false
      map[0].load({:value => "0"}, :value).should be false
    end
  end
end
