module WashOut
  # The WashOut::Dispatcher module should be included in a controller acting
  # as a SOAP endpoint. It includes actions for generating WSDL and handling
  # SOAP requests.
  module Dispatcher
    # A SoapError exception can be raised to return a correct SOAP error
    # response.
    class SoapError < Exception; end

    # This action generates the WSDL for defined SOAP methods.
    def wsdl
      @map       = self.class.wsdl_methods
      @name      = controller_path.gsub('/', '_')
      @namespace = 'urn:WashOut'

      render :template => 'wash_with_soap/wsdl'
    end

    # This action maps the SOAP action to a controller method defined with
    # +wsdl_method+.
    def soap
      map     = self.class.wsdl_methods
      method  = request.env['HTTP_SOAPACTION'].gsub(/^\"(.*)\"$/, '\1')
      current = map[method]

      raise SoapError, "Method #{method} does not exists" unless current

      xml_data = params['Envelope']['Body'][method]

      # Like proc{}
      args = xml_data.map { |opt, value| current[:in][opt].load(value) }

      result = send(method, *args)

      result = { 'value' => result } unless result.is_a? Hash
      @result = Hash[*current[:out].values.map do |param|
        [param, param.store(result[param.name])]
      end.flatten]

      render :template => 'wash_with_soap/response'
    end

    private

    def self.included(controller)
      controller.send :rescue_from, SoapError, :with => :wash_out_error
    end

    def wash_out_error(error)
      @error_message = error.message

      render :template => 'wash_with_soap/error', :status => 500
    end
  end
end
