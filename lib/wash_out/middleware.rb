class WashOut::Middleware
  def initialize app
    @app = app
  end

  def call env
    begin
      @app.call env
    rescue REXML::ParseException => e
      self.class.raise_or_render_rexml_parse_error e, env
    end
  end

  def self.raise_or_render_rexml_parse_error e, env
    raise e unless env.has_key? 'HTTP_SOAPACTION'
  
    # Normally input would be a StringIO, but Passenger has a different API:
    input = env['rack.input']
    req = if input.respond_to? :string then input.string else input.read end

    env['rack.errors'].puts <<-EOERR
WashOut::Exception: #{e.continued_exception} for:
#{req}
    EOERR
    [400, {'Content-Type' => 'text/xml'},
      [render_client_soap_fault("Error parsing SOAP Request XML")]]
  end

  def self.render_client_soap_fault msg
    xml = Builder::XmlMarkup.new
    xml.tag! 'soap:Envelope', 'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance' do
        xml.tag! 'soap:Body' do
          xml.tag! 'soap:Fault', :encodingStyle => 'http://schemas.xmlsoap.org/soap/encoding/' do
            xml.faultcode 'Client'
            xml.faultstring msg
          end
        end
      end
  end
end
