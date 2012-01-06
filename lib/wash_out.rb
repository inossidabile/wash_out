require 'wash_out/engine'
require 'wash_out/param'
require 'wash_out/dispatcher'
require 'wash_out/soap'
require 'wash_out/router'

module ActionDispatch::Routing
  class Mapper
    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_out(controller_name, options={})
      match "#{controller_name}/wsdl" => "#{controller_name}#_generate_wsdl", :via => :get
      match "#{controller_name}/action" => WashOut::Router.new(controller_name), :defaults => { :action => '_action' }
    end
  end
end

Mime::Type.register "application/soap+xml", :soap
ActionController::Renderers.add :soap do |what, options|
  _render_soap(what, options)
end