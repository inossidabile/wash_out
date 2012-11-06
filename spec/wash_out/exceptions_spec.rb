require 'spec_helper'
require 'wash_out/exceptions'
require 'rexml/document'

describe WashOut::Exceptions do
  it 'handles REXML parse errors' do
    [
      [ '<hi>', /No close tag/ ],
      [ '<hi', /missing tag start/ ],
      [ '<xs><x></xs>', /unconsumed char/ ],
    ].each do |input, expected|
      begin
        REXML::Document.new input
        fail "Expecte parse error for " + input
      rescue REXML::ParseException => e
        output = WashOut::Exceptions.render_rexml_parse_error e
        output.should =~ expected
        output.should include 'soap:Fault'
        output.should_not include __FILE__
      end
    end
  end
end
