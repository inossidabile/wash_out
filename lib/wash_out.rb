require 'virtus'
require 'wash_out/configurable'
require 'wash_out/soap_config'
require 'wash_out/soap'
require 'wash_out/engine'
require 'wash_out/param'
require 'wash_out/dispatcher'
require 'wash_out/soap'
require 'wash_out/router'
require 'wash_out/type'
require 'wash_out/model'
require 'wash_out/wsse'
require 'wash_out/middleware'

module ActionDispatch::Routing
  class Mapper
    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_out(controller_name, options={})
      options.reverse_merge!(@scope) if @scope
      controller_class_name = [options[:module], controller_name].compact.join("/")

      match "#{controller_name}/wsdl"   => "#{controller_name}#_generate_wsdl", :via => :get, :format => false
      match "#{controller_name}/action" => WashOut::Router.new(controller_class_name), :via => [:get, :post], :defaults => { :controller => controller_class_name, :action => '_action' }, :format => false
    end
  end
end

Virtus::Attribute.class_eval do
  accept_options :minoccurs, :maxoccurs, :nillable
  minoccurs 1 
  maxoccurs 1
  nillable true
end
  
Mime::Type.register "application/soap+xml", :soap
ActiveRecord::Base.send :extend, WashOut::Model if defined?(ActiveRecord)

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
    include WashOut::SOAP
    self.soap_config = options
  end
end