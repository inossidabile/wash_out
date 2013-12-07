#encoding:utf-8

require 'spec_helper'

describe WashOut::Rails::Controller do

  class Dispatcher < ApplicationController
    soap_service

    def params
      @_params
    end
  end

  it "finds nested hashes" do
    WashOut::Middlewares::Router.deep_select(:foo => 1){|k,v| k == :foo}.should == [1]
    WashOut::Middlewares::Router.deep_select({:foo => {:foo => 1}}){|k,v| k == :foo}.should == [{:foo => 1}, 1]
  end

  it "replaces nested hashed" do
    WashOut::Middlewares::Router.deep_replace_href({:foo => {:@href => 1}}, {1 => 2}).should == {:foo => 2}
    WashOut::Middlewares::Router.deep_replace_href({:bar => {:foo => {:@href => 1}}}, {1 => 2}).should == {:bar => {:foo => 2}}
  end

  xit "parses typical request" do
    dispatcher = Dispatcher.mock("<foo>1</foo>")
    dispatcher._parse_soap_parameters
    dispatcher.params.should == {:foo => "1"}
  end

  xit "parses href request" do
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
    let(:soap_config) { OpenStruct.new(camelize_wsdl: false) }
    it "should load params for an array" do
      spec = WashOut::Param.parse_def(soap_config, {:my_array => [:integer] } )
      xml_data = {:my_array => [1, 2, 3]}
      dispatcher._load_params(spec, xml_data).should == {"my_array" => [1, 2, 3]}
    end

    it "should load params for an empty array" do
      spec = WashOut::Param.parse_def(soap_config, {:my_array => [:integer] } )
      xml_data = {}
      dispatcher._load_params(spec, xml_data).should == {}
    end

    it "should load params for a nested array" do
      spec = WashOut::Param.parse_def(soap_config, {:nested => {:my_array => [:integer]}} )
      xml_data = {:nested => {:my_array => [1, 2, 3]}}
      dispatcher._load_params(spec, xml_data).should == {"nested" => {"my_array" => [1, 2, 3]}}
    end

    it "should load params for an empty nested array" do
      spec = WashOut::Param.parse_def(soap_config, {:nested => {:empty => [:integer] }} )
      xml_data = {:nested => nil}
      dispatcher._load_params(spec, xml_data).should == {"nested" => {}}
    end

  end

end
