require 'spec_helper'
require 'wash_out/middleware'
require 'rexml/document'

describe WashOut::Middleware do
  it 'handles Rack environment variables' do
    err = begin
      REXML::Document.new '<hi>'
    rescue REXML::ParseException => e
      e
    end

    env = {}
    expect {
      WashOut::Middleware.raise_or_render_rexml_parse_error err, env
    }.to raise_exception(REXML::ParseException)

    env['HTTP_SOAPACTION'] = 'pretend_action'
    env['rack.errors'] = double 'logger', {:puts => true} 
    env['rack.input'] = double 'basic-rack-input', {:string => '<hi>'} 
    result = WashOut::Middleware.raise_or_render_rexml_parse_error err, env
    expect(result[0]).to eq 400
    expect(result[1]['Content-Type']).to eq 'text/xml'
    msg = result[2][0]
    expect(msg).to include 'Error parsing SOAP Request XML'
    expect(msg).to include 'soap:Fault'
    expect(msg).not_to include __FILE__
    
    env['rack.input'] = double 'passenger-input', {:read => '<hi>'}
    result = WashOut::Middleware.raise_or_render_rexml_parse_error err, env
    expect(result[0]).to eq 400
  end
end