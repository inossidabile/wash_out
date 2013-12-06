module WashOut
  module Middlewares
    class Catcher
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call env
      rescue REXML::ParseException => e
        raise e unless env.has_key?('HTTP_SOAPACTION')

        input = env['rack.input'].respond_to?(:string) ? env['rack.input'].string
                                                       : env['rack.input'].read

        env['rack.errors'].puts <<-TEXT
          WashOut::Exception: #{e.continued_exception} for:
          #{input}
        TEXT

        [
          400,
          {'Content-Type' => 'text/xml'},
          [self.class.render_client_soap_fault("Error parsing SOAP Request XML")]
        ]
      end

      def self.render_client_soap_fault(msg)
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
  end
end