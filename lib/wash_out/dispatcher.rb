require 'nori'

module WashOut
  # The WashOut::Dispatcher module should be included in a controller acting
  # as a SOAP endpoint. It includes actions for generating WSDL and handling
  # SOAP requests.
  module Dispatcher
    # A SOAPError exception can be raised to return a correct SOAP error
    # response.
    class SOAPError < Exception; end

    # This action generates the WSDL for defined SOAP methods.
    def _wsdl
      @map       = self.class.soap_actions
      @namespace = 'urn:WashOut'
      @name      = controller_path.gsub('/', '_')

      render :template => 'wash_with_soap/wsdl'
    end

    # This action maps the SOAP action to a controller method defined with
    # +soap_action+.
    def _action
      map       = self.class.soap_actions
      method    = request.env['HTTP_SOAPACTION'].gsub(/^\"(.*)\"$/, '\1')
      @_current = map[method.force_encoding('UTF-8')]

      raise SOAPError, "Method #{method} does not exists" unless @_current

      params = Nori.parse(request.body)
      xml_data = params[:envelope][:body][method.downcase.to_sym]

      @_params = HashWithIndifferentAccess.new
      (xml_data || {}).map do |opt, value|
        param = @_current[:in].find { |param| param.name.underscore.to_sym == opt }
        raise SOAPError, "unknown parameter #{opt}" unless param

        @_params[opt] = param.load(value)
      end

      send(@_current[:to])
    end

    def _render_soap(result, options)
      result = { 'value' => result } unless result.is_a? Hash
      result = HashWithIndifferentAccess.new(result)
      result = Hash[*@_current[:out].map do |param|
        [param, param.store(result[param.name])]
      end.flatten]

      render :template => 'wash_with_soap/response',
             :locals => { :result => result }
    end

    # Render a SOAP error response.
    #
    # Rails do not support sequental rescue_from handling, that is, rescuing an
    # exception from a rescue_from handler. Hence this function is a public API.
    def render_soap_error(message)
      render :template => 'wash_with_soap/error', :status => 500,
             :locals => { :error_message => message }
    end

    private

    def self.included(controller)
      controller.send :rescue_from, SOAPError, :with => :_render_soap_exception
    end

    def _render_soap_exception(error)
      render_soap_error(error.message)
    end
  end
end
