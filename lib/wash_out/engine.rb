module WashOut
  class Engine < ::Rails::Engine

    def self.defaults
      {
        parser:               :rexml,
        namespace:            'urn:WashOut',
        wsdl_style:           'rpc',
        snakecase_input:      false,
        camelize_wsdl:        false,
        catch_xml_errors:     false,
        wsse_username:        nil,
        wsse_password:        nil
      }
    end

    config.wash_out = ActiveSupport::OrderedOptions.new.merge!(defaults)

    initializer "wash_out.configuration" do |app|
      if app.config.wash_out[:catch_xml_errors]
        app.config.middleware.insert_after 'ActionDispatch::ShowExceptions', WashOut::Middlewares::Catcher
      end
    end

  end
end
