require 'spec_helper'
require 'wash_out/exceptions'
require 'rexml/document'

describe WashOut::Middleware do
  it 'handles Rack environment variables' do
    err = begin
      REXML::Document.new '<hi>'
    rescue REXML::ParseException => e
      e
    end
    
    env = {}
    lambda do
      WashOut::Middleware.raise_or_render_rexml_parse_error err, env
    end.should raise_error err

    env['HTTP_SOAPACTION'] = 'pretend_action'
    env['rack.errors'] = double 'logger', {:puts => true} 
    env['rack.input'] = double 'basic-rack-input', {:string => '<hi>'} 
    result = WashOut::Middleware.raise_or_render_rexml_parse_error err, env
    result[0].should == 400
    result[1]['Content-Type'].should == 'text/xml'
    msg = result[2][0]
    msg.should include 'No close tag'
    msg.should include 'soap:Fault'
    msg.should_not include __FILE__
    
    env['rack.input'] = double 'passenger-input', {:read => '<hi>'}
    result = WashOut::Middleware.raise_or_render_rexml_parse_error err, env
    result[0].should == 400
  end
end