#encoding:utf-8

require 'spec_helper'

describe WashOut::Dispatcher do

  class Dispatcher < ApplicationController
    soap_service

    def params
      @_params
    end
  end

  it "finds nested hashes" do
    expect(WashOut::Dispatcher.deep_select(:foo => 1){|k,v| k == :foo}).to eq [1]
    expect(WashOut::Dispatcher.deep_select({:foo => {:foo => 1}}){|k,v| k == :foo}).to eq([{:foo => 1}, 1])
  end

  it "replaces nested hashed" do
    expect(WashOut::Dispatcher.deep_replace_href({:foo => {:@href => 1}}, {1 => 2})).to eq({:foo => 2})
    expect(WashOut::Dispatcher.deep_replace_href({:bar => {:foo => {:@href => 1}}}, {1 => 2})).to eq({:bar => {:foo => 2}})
  end

  xit "parses typical request" do
    dispatcher = Dispatcher.mock("<foo>1</foo>")
    dispatcher._parse_soap_parameters
    expect(dispatcher.params).to eq({:foo => "1"})
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
    expect(dispatcher.params[:root][:request][:entities]).to eq({
      :foo => {:bar=>"1"},
      :sub => {:foo=>"1", :@id=>"id2"},
      :@id => "id1"
    })
  end

  describe "#_map_soap_parameters" do
    let(:dispatcher) { Dispatcher.new }
    let(:soap_config) { WashOut::SoapConfig.new(camelize_wsdl: false) }

    before do
      allow(dispatcher).to receive(:action_spec).and_return(in: WashOut::Param.parse_def(soap_config, { foo: { "@bar" => :string, empty: :string } } ))
      allow(dispatcher).to receive(:xml_data).and_return(foo: { "@bar" => "buzz", empty: { :"@xsi:type" => "xsd:string" } })
    end

    it "should handle empty strings that have been parsed wrong by nori, but preserve attrs" do
      dispatcher._map_soap_parameters
      expect(dispatcher.params).to eq("foo" => { "bar" => "buzz", "empty" => nil })
    end
  end

  describe "#_load_params" do
    let(:dispatcher) { Dispatcher.new }
    let(:soap_config) { WashOut::SoapConfig.new({ camelize_wsdl: false }) }
    it "should load params for an array" do
      spec = WashOut::Param.parse_def(soap_config, {:my_array => [:integer] } )
      xml_data = {:my_array => [1, 2, 3]}
      expect(dispatcher._load_params(spec, xml_data)).to eq({"my_array" => [1, 2, 3]})
    end

    it "should load params for an empty array" do
      spec = WashOut::Param.parse_def(soap_config, {:my_array => [:integer] } )
      xml_data = {}
      expect(dispatcher._load_params(spec, xml_data)).to eq({})
    end

    it "should load params for a nested array" do
      spec = WashOut::Param.parse_def(soap_config, {:nested => {:my_array => [:integer]}} )
      xml_data = {:nested => {:my_array => [1, 2, 3]}}
      expect(dispatcher._load_params(spec, xml_data)).to eq({"nested" => {"my_array" => [1, 2, 3]}})
    end

    it "should load params for an empty nested array" do
      spec = WashOut::Param.parse_def(soap_config, {:nested => {:empty => [:integer] }} )
      xml_data = {:nested => nil}
      expect(dispatcher._load_params(spec, xml_data)).to eq({"nested" => {}})
    end

  end

end
