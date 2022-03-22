require 'spec_helper'
require 'wash_out/router'

describe WashOut::Router do
  it 'returns a 200 with empty soap action' do

    mock_controller do
      # nothing
    end

    env = {}
    env['REQUEST_METHOD'] = 'GET'
    env['rack.input'] = double 'basic-rack-input', {:string => ''}
    result = WashOut::Router.new('Route::Space::Api').call env

    expect(result[0]).to eq(500)
    expect(result[1]['Content-Type']).to eq('text/xml; charset=utf-8')
  end

  def parse_soap_params_from_xml(filename)
    xml = File.read(File.expand_path("../../../fixtures/#{filename}", __FILE__))
    env = {'rack.input' => StringIO.new(xml)}

    router = WashOut::Router.new('')
    controller = double("controller", soap_config: WashOut::SoapConfig.new)
    allow(router).to receive(:controller).and_return(controller)

    router.parse_soap_parameters(env)[:Envelope][:Body]
  end

  it "returns refs to arrays correctly" do
    body = parse_soap_params_from_xml('ref_to_one_array.xml')

    expect(body[:list][:Item]).to eq(["1", "2"])
  end

  it "returns refs to multiple arrays correctly" do
    body = parse_soap_params_from_xml('refs_to_arrays.xml')

    expect(body[:first_list][:Item]).to eq(["1", "2"])
    expect(body[:second_list][:Item]).to eq(["11", "22"])
  end

  it "returns nested refs to multiple arrays correctly" do
    body = parse_soap_params_from_xml('nested_refs_to_arrays.xml')

    expect(body[:parent][:first_list][:Item]).to eq(["1", "2"])
    expect(body[:parent][:second_list][:Item]).to eq(["11", "22"])
  end
end
