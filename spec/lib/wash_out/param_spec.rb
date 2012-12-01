#encoding:utf-8

require 'spec_helper'

describe WashOut::Param do

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