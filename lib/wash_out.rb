require 'wash_out/engine'
require 'wash_out/param'
require 'wash_out/dispatcher'
require 'wash_out/wash_with_soap'

module ActionDispatch::Routing
  class Mapper
    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_with_soap(controller)
      match "#{controller.to_s}/wsdl" => "#{controller.to_s}#wsdl"
      match "#{controller.to_s}/soap" => "#{controller.to_s}#soap"
    end
  end
end
