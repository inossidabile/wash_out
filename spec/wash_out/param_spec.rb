#encoding:utf-8

require 'spec_helper'

describe WashOut::Param do

  it "loads custom_types" do
    class Abraka1 < WashOut::Type
      map(
        :test => :string
      )
    end
    class Abraka2 < WashOut::Type
      type_name 'test'
      map :foo => Abraka1
    end

    map = WashOut::Param.parse_def Abraka2

    map.should be_a_kind_of(Array)
    map[0].name.should == 'Value'
    map[0].map[0].name.should == 'Foo'
    map[0].map[0].map[0].name.should == 'Test'
  end

end