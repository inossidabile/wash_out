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
    result = WashOut::Router.new('Api').call env

    expect(result[0]).to eq(200)
    #expect(result[1]['Content-Type']).to eq('text/xml')

    msg = result[2][0]
    expect(msg).to eq('OK')
  end
end
