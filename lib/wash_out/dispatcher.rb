module WashOut
  module Dispatcher
    class SoapError < Exception; end

    def wsdl
      @map       = self.class.wsdl_methods
      @name      = controller_path.gsub('/', '_')
      @namespace = 'urn:WashOut'

      render :template => 'wash_with_soap/wsdl'
    end

    def soap
      map     = self.class.wsdl_methods
      method  = request.env['HTTP_SOAPACTION'].gsub(/^\"(.*)\"$/, '\1')
      current = map[method]

      raise SoapError, "Method #{@method} does not exists" unless current

      xml_data = params['Envelope']['Body'][method]

      # Like proc{}
      args = xml_data.map { |opt, value| current[:in][opt].load(value) }

      result = send(method, *args)

      result = { "value" => result } unless result.is_a? Hash
      @result = current[:out].map { |opt, value| current[:out][opt].load(value) }

      render :template => 'wash_with_soap/response'
    end

    private

    def self.included(controller)
      controller.send :rescue_from, SoapError, :with => :wash_out_error
    end

    def wash_out_error(error)
      @error_message = error.message

      render :template => 'wash_with_soap/error'
    end
  end
end