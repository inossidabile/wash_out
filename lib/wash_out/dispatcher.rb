module WashOut
  # The WashOut::Dispatcher module should be included in a controller acting
  # as a SOAP endpoint. It includes actions for generating WSDL and handling
  # SOAP requests.
  module Dispatcher
    # A SoapError exception can be raised to return a correct SOAP error
    # response.
    class SoapError < Exception; end

    # This action generates the WSDL for defined SOAP methods.
    def _wsdl
      @map       = self.class.soap_actions
      @name      = controller_path.gsub('/', '_')
      @namespace = 'urn:WashOut'

      render :template => 'wash_with_soap/wsdl'
    end

    # This action maps the SOAP action to a controller method defined with
    # +soap_action+.
    def _soap
      map     = self.class.soap_actions
      method  = request.env['HTTP_SOAPACTION'].gsub(/^\"(.*)\"$/, '\1')
      current = map[method]

      raise SoapError, "Method #{method} does not exists" unless current

      xml_data = params['Envelope']['Body'][method]

      params = xml_data.map do |opt, value|
        current[:in].find { |param| param.name == opt }.load(value)
      end
      @_params = HashWithIndifferentAccess.new(params)

      send(current[:to])
    end

    def _render_soap(result, options)
      result = { 'value' => result } unless result.is_a? Hash
      result = HashWithIndifferentAccess.new(result)
      result = Hash[*current[:out].map do |param|
        [param, param.store(result[param.name])]
      end.flatten]

      render :template => 'wash_with_soap/response',
             :locals => { :result => result }
    end

    private

    def self.included(controller)
      controller.send :rescue_from, SoapError, :with => :_render_soap_error
    end

    def _render_soap_error(error)
      render :template => 'wash_with_soap/error', :status => 500,
             :locals => { :error_message => error.message }
    end
  end
end
