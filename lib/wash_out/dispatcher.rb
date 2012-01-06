require 'nori'

module WashOut
  # The WashOut::Dispatcher module should be included in a controller acting
  # as a SOAP endpoint. It includes actions for generating WSDL and handling
  # SOAP requests.
  module Dispatcher
    # A SOAPError exception can be raised to return a correct SOAP error
    # response.
    class SOAPError < Exception; end

    # This filter parses the SOAP request and puts it into +params+ array.
    def _parse_soap_parameters
      soap_action = request.env['wash_out.soap_action']
      action_spec = self.class.soap_actions[soap_action]

      strip = Nori.strip_namespaces?

      Nori.strip_namespaces = true
      params = Nori.parse(request.body)
      xml_data = params[:envelope][:body][soap_action.underscore.to_sym]
      Nori.strip_namespaces = strip

      @_params = HashWithIndifferentAccess.new
      (xml_data || {}).map do |opt, value|
        unless opt[0] == '@'
          param = action_spec[:in].find { |param| param.name.underscore.to_sym == opt }
          raise SOAPError, "unknown parameter #{opt}" unless param

          @_params[param.name] = param.load(value)
        end
      end
    end

    # This action generates the WSDL for defined SOAP methods.
    def _generate_wsdl
      @map       = self.class.soap_actions
      @namespace = 'urn:WashOut'
      @name      = controller_path.gsub('/', '_')

      render :template => 'wash_with_soap/wsdl'
    end

    # Render a SOAP response.
    def _render_soap(result, options)
      soap_action = request.env['wash_out.soap_action']
      action_spec = self.class.soap_actions[soap_action]

      result = { 'value' => result } unless result.is_a? Hash
      result = HashWithIndifferentAccess.new(result)
      result = Hash[*action_spec[:out].map do |param|
        [param, param.store(result[param.name])]
      end.flatten]

      render :template => 'wash_with_soap/response',
             :locals => { :result => result }
    end

    # This action is a fallback for all undefined SOAP actions.
    def _invalid_action
      render_soap_error("Cannot find SOAP action mapping for #{request.env['wash_out.soap_action']}")
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
      controller.send :helper, :wash_out
      controller.send :before_filter, :_parse_soap_parameters, :except => [ :_generate_wsdl, :_invalid_action ]
    end

    def _render_soap_exception(error)
      render_soap_error(error.message)
    end
  end
end
