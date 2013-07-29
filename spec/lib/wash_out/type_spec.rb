#encoding:utf-8

require 'spec_helper'

describe WashOut::Type do

  it "defines custom type" do
    class Abraka1 < WashOut::Type
      map :test => :string
    end
    class Abraka2 < WashOut::Type
      type_name 'test'
      map :foo => Abraka1
    end

    Abraka1.wash_out_param_name.should == 'abraka1'
    Abraka1.wash_out_param_map.should == {:test => :string}

    Abraka2.wash_out_param_name.should == 'test'
    Abraka2.wash_out_param_map.should == {:foo => Abraka1}
  end

  it "allows arrays inside custom types" do
    class Abraka1 < WashOut::Type
      map :test => :string
    end
    class Abraka2 < WashOut::Type
      type_name 'test'
      map :foo => [:bar => Abraka1]
    end

    Abraka1.wash_out_param_name.should == 'abraka1'
    Abraka1.wash_out_param_map.should == {:test => :string}

    Abraka2.wash_out_param_name.should == 'test'
    Abraka2.wash_out_param_map.should == {:foo => [:bar => Abraka1]}
  end

end