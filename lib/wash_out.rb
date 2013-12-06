require 'wash_out/engine'
require 'wash_out/param'
require 'wash_out/dispatcher'
require 'wash_out/type'
require 'wash_out/active_record'
require 'wash_out/wsse'
require 'wash_out/middlewares/router'
require 'wash_out/middlewares/catcher'
require 'wash_out/exceptions/programmer_error'
require 'wash_out/exceptions/soap_error'

module ActionDispatch::Routing
  class Mapper
    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_out(controller_name, options={})
      options.reverse_merge!(@scope) if @scope
      controller_class_name = [options[:module], controller_name].compact.join("/")

      match "#{controller_name}/wsdl"   => "#{controller_name}#_generate_wsdl", :via => :get, :format => false
      match "#{controller_name}/action" => WashOut::Middlewares::Router.new(controller_class_name), :via => [:get, :post], :defaults => { :controller => controller_class_name, :action => '_action' }, :format => false
    end
  end
end

Mime::Type.register "application/soap+xml", :soap
ActiveRecord::Base.send :extend, WashOut::ActiveRecord if defined?(ActiveRecord)

ActionController::Renderers.add :soap do |what, options|
  _render_soap(what, options)
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
    include WashOut::Dispatcher
    self.soap_config = options
  end
end