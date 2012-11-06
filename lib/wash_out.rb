require 'wash_out/engine'
require 'wash_out/param'
require 'wash_out/dispatcher'
require 'wash_out/soap'
require 'wash_out/router'
require 'wash_out/type'
require 'wash_out/model'
require 'wash_out/wsse'
require 'wash_out/exceptions'

module ActionDispatch::Routing
  class Mapper
    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_out(controller_name, options={})
      options.reverse_merge!(@scope) if @scope
      controller_class_name = [options[:module], controller_name].compact.join("/")

      match "#{controller_name}/wsdl"   => "#{controller_name}#_generate_wsdl", :via => :get, :format => false
      match "#{controller_name}/action" => WashOut::Router.new(controller_class_name), :defaults => { :controller => controller_class_name, :action => '_action' }, :format => false
    end
  end
end

Mime::Type.register "application/soap+xml", :soap
ActiveRecord::Base.send :extend, WashOut::Model if defined?(ActiveRecord)

ActionController::Renderers.add :soap do |what, options|
  _render_soap(what, options)
end

module ActionView
  class Base
    cattr_accessor :washout_namespace
    @@washout_namespace = false
  end
end
