#encoding:utf-8

require 'spec_helper'

describe WashOut::Dispatcher do

  class TestBody
    attr_accessor :read
    def initialize(read); @read = read; end
  end

  class TestRequest
    attr_accessor :body
    def initialize(body); @body = body; end
  end

  class Dispatcher < ApplicationController
    include WashOut::SOAP

    def self.mock(text="")
      dispatcher = self.new
      dispatcher.request = TestRequest.new(TestBody.new(text))
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
    XML
    dispatcher._parse_soap_parameters
    dispatcher.params[:request][:entities].should == {:foo=>{:bar=>"1"}, :sub=>{:foo=>"1", :@id=>"id2"}, :@id=>"id1"}
  end

end
