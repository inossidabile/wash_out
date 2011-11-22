require 'wash_out/engine'
require 'wash_out/param'
require 'wash_out/dispatcher'
require 'wash_out/soap'

module ActionDispatch::Routing
  class Mapper
    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_out(controller)
      match "#{controller.to_s}/wsdl" => "#{controller.to_s}#_wsdl"
      match "#{controller.to_s}/action" => "#{controller.to_s}#_soap"
    end
  end
end

Mime::Type.register "application/soap+xml", :soap
ActionController::Renderers.add :soap do |what, options|
  _render_soap(what, options)
end
