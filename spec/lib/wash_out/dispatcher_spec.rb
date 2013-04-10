#encoding:utf-8

require 'spec_helper'

describe WashOut::Dispatcher do

  class Dispatcher < ApplicationController
    include WashOut::SOAP

    def self.mock(text="")
      dispatcher = self.new
      dispatcher.request = OpenStruct.new(:body => OpenStruct.new(:read => text))
      dispatcher
    end

    def params
      @_params
    end
  end

  it "finds nested hashes" do
    WashOut::Dispatcher.deep_select(:foo => 1){|k,v| k == :foo}.should == [1]
    WashOut::Dispatcher.deep_select({:foo => {:foo => 1}}){|k,v| k == :foo}.should == [{:foo => 1}, 1]
  end

  it "replaces nested hashed" do
    WashOut::Dispatcher.deep_replace_href({:foo => {:@href => 1}}, {1 => 2}).should == {:foo => 2}
    WashOut::Dispatcher.deep_replace_href({:bar => {:foo => {:@href => 1}}}, {1 => 2}).should == {:bar => {:foo => 2}}
  end

  it "parses typical request" do
    dispatcher = Dispatcher.mock("<foo>1</foo>")
    dispatcher._parse_soap_parameters
    dispatcher.params.should == {:foo => "1"}
  end

  it "parses href request" do
    dispatcher = Dispatcher.mock <<-XML
      <root>
        <request>
          <entities href="#id1">
          </entities>
        </request>
        <entity id="id1">
          <foo><bar>1</bar></foo>
          <sub href="#id2" />
        </entity>
        <ololo id="id2">
          <foo>1</foo>
        </ololo>
      </root>
    XML
    dispatcher._parse_soap_parameters
    dispatcher.params[:root][:request][:entities].should == {
      :foo => {:bar=>"1"},
      :sub => {:foo=>"1", :@id=>"id2"},
      :@id => "id1"
    }
  end

  describe "#_load_params" do
    let(:dispatcher) { Dispatcher.new }

    it "should load params for an array" do
      spec = WashOut::Param.parse_def( {:my_array => [:integer] } )
      xml_data = {:my_array => [1, 2, 3]}
      dispatcher._load_params(spec, xml_data).should == {"my_array" => [1, 2, 3]}
    end

    it "should load params for an empty array" do
      spec = WashOut::Param.parse_def( {:my_array => [:integer] } )
      xml_data = {}
      dispatcher._load_params(spec, xml_data).should == {}
    end

    it "should load params for a nested array" do
      spec = WashOut::Param.parse_def( {:nested => {:my_array => [:integer]}} )
      xml_data = {:nested => {:my_array => [1, 2, 3]}}
      dispatcher._load_params(spec, xml_data).should == {"nested" => {"my_array" => [1, 2, 3]}}
    end

    it "should load params for an empty nested array" do
      spec = WashOut::Param.parse_def( {:nested => {:empty => [:integer] }} )
      xml_data = {:nested => nil}
      dispatcher._load_params(spec, xml_data).should == {"nested" => {}}
    end

  end

end
