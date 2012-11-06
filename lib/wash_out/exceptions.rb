class WashOut::Exceptions
  def initialize app
    @app = app
  end

  def call env
    begin
      @app.call env
    rescue Exception => e
      raise e unless env.has_key? 'HTTP_SOAPACTION'
      log = proc {|msg| env['rack.errors'].puts 'WashOut::Exception: ' + msg}
      input = env['rack.input'].string
      case e
      when REXML::ParseException
        log[e.continued_exception.to_s + " for: " + input]
        [400, {'Content-Type' => 'text/xml'},
          [self.class.render_rexml_parse_error(e)]]
      else
        log["The request:\n#{input}\n\nCaused: #{e}\n#{e.backtrace.join "\n"}"]
        [500, {'Content-Type' => 'text/xml'},
          [self.class.render_soap_fault('Server', e)]]
      end
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
