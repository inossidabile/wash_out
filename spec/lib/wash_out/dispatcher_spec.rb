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
    expect(WashOut::Dispatcher.deep_select(:foo => 1){|k,v| k == :foo}).to eq([1])
    expect(WashOut::Dispatcher.deep_select({:foo => {:foo => 1}}){|k,v| k == :foo}).to eq([{:foo => 1}, 1])
  end

  it "replaces nested hashed" do
    expect(WashOut::Dispatcher.deep_replace_href({:foo => {:@href => 1}}, {1 => 2})).to eq({:foo => 2})
    expect(WashOut::Dispatcher.deep_replace_href({:bar => {:foo => {:@href => 1}}}, {1 => 2})).to eq({:bar => {:foo => 2}})
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
