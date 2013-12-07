require 'wash_out/exceptions/programmer_error'
require 'wash_out/exceptions/soap_error'

require 'wash_out/middlewares/router'
require 'wash_out/middlewares/catcher'

require 'wash_out/wsse'
require 'wash_out/type'
require 'wash_out/param'

require 'wash_out/rails/active_record'
require 'wash_out/rails/controller'
require 'wash_out/rails/engine'

module WashOut
  def self.normalize(string, config)
    return string.to_s if !config || !config.camelize_wsdl
    return string.to_s.camelize(:lower) if config.camelize_wsdl == 'lower'
    return string.to_s.camelize
  end
end