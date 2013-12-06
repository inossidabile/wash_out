require 'spec_helper'
require 'wash_out/middlewares/catcher'
require 'rexml/document'

describe WashOut::Middlewares::Catcher do
  context 'catches REXML' do
    let(:app)  { lambda {|env| REXML::Document.new '<hi>' } }
    let(:rack) { WashOut::Middlewares::Catcher.new(app) }
    let(:env)  { {} }

    it 'passes exceptions through when not in SOAP mode' do
      lambda { rack.call(env) }.should raise_exception
    end

    context 'intercepts when in SOAP mode' do
      subject { rack.call(env) }

      context 'for basic rack servers' do
        let(:env) do
          {
            'HTTP_SOAPACTION' => 'pretend_action',
            'rack.errors'     => double('logger', puts: true),
            'rack.input'      => double('basic-rack-input', string: 'hi')
          }
        end

        it do
          subject[0].should == 400
          subject[1]['Content-Type'].should == 'text/xml'
          subject[2][0].should include 'Error parsing SOAP Request XML'
          subject[2][0].should include 'soap:Fault'
          subject[2][0].should_not include __FILE__
        end
      end

      context 'for passenger' do
        let(:env) do
          {
            'HTTP_SOAPACTION' => 'pretend_action',
            'rack.errors'     => double('logger', puts: true),
            'rack.input'      => double('basic-rack-input', read: 'hi')
          }
        end

        it do
          subject[0].should == 400
          subject[1]['Content-Type'].should == 'text/xml'
          subject[2][0].should include 'Error parsing SOAP Request XML'
          subject[2][0].should include 'soap:Fault'
          subject[2][0].should_not include __FILE__
        end
      end
    end
  end
end