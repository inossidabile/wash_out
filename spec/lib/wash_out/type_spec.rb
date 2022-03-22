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

    expect(Abraka1.wash_out_param_name).to eq 'abraka1'
    expect(Abraka1.wash_out_param_map).to eq({:test => :string})

    expect(Abraka2.wash_out_param_name).to eq 'test'
    expect(Abraka2.wash_out_param_map).to eq({:foo => Abraka1})
  end

  it "allows arrays inside custom types" do
    class Abraka1 < WashOut::Type
      map :test => :string
    end
    class Abraka2 < WashOut::Type
      type_name 'test'
      map :foo => [:bar => Abraka1]
    end

    expect(Abraka1.wash_out_param_name).to eq 'abraka1'
    expect(Abraka1.wash_out_param_map).to eq({:test => :string})

    expect(Abraka2.wash_out_param_name).to eq 'test'
    expect(Abraka2.wash_out_param_map).to eq({:foo => [:bar => Abraka1]})
  end

end