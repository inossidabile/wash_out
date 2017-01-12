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

module WashOut
  def self.root
    File.expand_path '../..', __FILE__
  end
end

module ActionDispatch::Routing
  class Mapper
    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_out(controller_name, options={})
      if @scope
        scope_frame = @scope.respond_to?(:frame) ? @scope.frame : @scope
        options.each{ |key, value|  scope_frame[key] = value }
      end

      controller_class_name = [scope_frame[:module], controller_name].compact.join("/").underscore

      match "#{controller_name}/wsdl"   => "#{controller_name}#_generate_wsdl", :via => :get, :format => false,
        :as => "#{controller_class_name}_wsdl"
      match "#{controller_name}/action" => WashOut::Router.new(controller_class_name), :via => [:get, :post],
        :defaults => { :controller => controller_class_name, :action => 'soap' }, :format => false,
        :as => "#{controller_class_name}_soap"
    end
  end
end

Mime::Type.register "application/soap+xml", :soap
ActiveRecord::Base.send :extend, WashOut::Model if defined?(ActiveRecord)

ActionController::Renderers.add :soap do |what, options|
  _render_soap(what, options)
end

ActionController::Metal.class_eval do

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

if Rails::VERSION::MAJOR >= 5
  if defined?(ActionView::Rendering)
    module ActionController
      module ApiRendering
        include ActionView::Rendering
      end
    end
  end

  ActiveSupport.on_load :action_controller do
    if self == ActionController::API
      include ActionController::Helpers
    end
  end
end
