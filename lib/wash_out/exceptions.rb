class WashOut::Exceptions
  def initialize app
    @app = app
  end

  def call env
    begin
      @app.call env
    rescue REXML::ParseException => e
      raise e unless env.has_key? 'HTTP_SOAPACTION'
      input = env['rack.input'].string
      env['rack.errors'].puts <<-EOERR
WashOut::Exception: #{e.continued_exception} for:
#{input}
      EOERR
      [400, {'Content-Type' => 'text/xml'},
        [self.class.render_rexml_parse_error(e)]]
    end
  end

  def self.render_rexml_parse_error e
    render_soap_fault 'Client', e.continued_exception.to_s
  end

  def self.render_soap_fault code, msg
    xml = Builder::XmlMarkup.new
    xml.tag! 'soap:Envelope', 'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance' do
        xml.tag! 'soap:Body' do
          xml.tag! 'soap:Fault', :encodingStyle => 'http://schemas.xmlsoap.org/soap/encoding/' do
            xml.faultcode code
            xml.faultstring msg
          end
        end
      end
  end
end
