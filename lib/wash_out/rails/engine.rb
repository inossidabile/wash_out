module WashOut
  module Rails
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

      initializer "wash_out.responders" do
        Mime::Type.register "application/soap+xml", :soap

        ActionController::Renderers.add :soap do |what, options|
          _render_soap(what, options)
        end
      end
    end
  end

  ActionDispatch::Routing::Mapper.class_eval do
    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_out(controller_name, options={})
      options.reverse_merge!(@scope) if @scope
      controller_path = [options[:module], controller_name].compact.join("/")

      # WSDL Route
      match "#{controller_name}/wsdl" => "#{controller_name}#_generate_wsdl",
        via:    :get,
        format: false

      # Responding point
      match "#{controller_name}/action" => WashOut::Middlewares::Router.new(controller_path),
        via:    [:get, :post],
        format: false
    end
  end

  ActionController::Base.class_eval do
    # Define a SOAP service. The function has no required +options+:
    # but allow any of :parser, :namespace, :wsdl_style, :snakecase_input,
    # :camelize_wsdl, :wsse_username, :wsse_password and :catch_xml_errors.
    #
    # Any of the the params provided allows for overriding the defaults
    # (like supporting multiple namespaces instead of application wide such)
    #
    def self.soap_service(options={})
      include WashOut::Rails::Controller
      self.soap_config = options
    end
  end

  if defined?(ActiveRecord)
    ActiveRecord::Base.class_eval do
      # Turns AR models into WashOut types
      extend WashOut::Rails::ActiveRecord
    end
  end
end