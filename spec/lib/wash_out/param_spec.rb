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
      map = WashOut::Param.parse_def Abraka2

      map.should be_a_kind_of(Array)
      map[0].name.should == 'value'
      map[0].map[0].name.should == 'foo'
      map[0].map[0].map[0].name.should == 'test'
    end

    it "respects camelization setting" do
      WashOut::Engine.camelize_wsdl = true

      map = WashOut::Param.parse_def Abraka2

      map.should be_a_kind_of(Array)
      map[0].name.should == 'Value'
      map[0].map[0].name.should == 'Foo'
      map[0].map[0].map[0].name.should == 'Test'
    end
  end

  it "should accept nested empty arrays" do
    map = WashOut::Param.parse_def( {:nested => {some_attr: :string, empty: [:integer] }} )
    map[0].load( {nested: nil}, :nested).should == {}
  end

  describe "booleans" do
    # following http://www.w3.org/TR/xmlschema-2/#boolean, only true, false, 0 and 1 are allowed.
    # Nori maps the strings true and false to TrueClass and FalseClass, but not 0 and 1.
    let(:map) { WashOut::Param.parse_def(value: :boolean) }

    it "should accept 'true' and '1'" do
      map[0].load({value: true}, :value).should be_true
      map[0].load({value: "1"}, :value).should be_true
    end

    it "should accept 'false' and '0'" do
      map[0].load({value: false}, :value).should be_false
      map[0].load({value: "0"}, :value).should be_false
    end

    it "should raise an error for invalid strings" do
      lambda { map[0].load({value: "some value"}, :value) }.should raise_error(WashOut::Dispatcher::SOAPError, /Invalid SOAP parameter/)
      lambda { map[0].load({value: "TRUE"}, :value) }.should raise_error(WashOut::Dispatcher::SOAPError, /Invalid SOAP parameter/)
    end

  end
end
