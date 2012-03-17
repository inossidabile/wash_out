require 'nori'

module WashOut
  # The WashOut::Dispatcher module should be included in a controller acting
  # as a SOAP endpoint. It includes actions for generating WSDL and handling
  # SOAP requests.
  module Dispatcher
    # A SOAPError exception can be raised to return a correct SOAP error
    # response.
    class SOAPError < Exception; end

    def namespace
      namespace   = ActionView::Base.washout_namespace if defined?(ActionView::Base)
      namespace ||= 'urn:WashOut'
    end

    # This filter parses the SOAP request and puts it into +params+ array.
    def _parse_soap_parameters
      soap_action = request.env['wash_out.soap_action']
      action_spec = self.class.soap_actions[soap_action]

      # Do not interfere with project-space Nori setup
      strip   = Nori.strip_namespaces?
      convert = Nori.convert_tags?
      Nori.strip_namespaces = true
      Nori.convert_tags_to { |tag| tag.snakecase.to_sym }

      params = Nori.parse(request.body)
      xml_data = params[:envelope][:body][soap_action.underscore.to_sym] || {}

      strip_empty_nodes = lambda{|hash|
        hash.each do |key, value|
          if value.is_a? Hash
            value = value.delete_if{|key, value| key.to_s[0] == '@'}

            if value.length > 0
              hash[key] = strip_empty_nodes.call(value)
            else
              hash[key] = nil
            end
          end
        end

        hash
      }

      xml_data = strip_empty_nodes.call(xml_data)

      # Reset Nori setup to project-space
      Nori.strip_namespaces = strip
      Nori.convert_tags_to convert

      @_params = HashWithIndifferentAccess.new

      action_spec[:in].each do |param|
        key = param.name.to_sym

        if xml_data.has_key? key
          @_params[param.name] = param.load(xml_data, key)
        end
      end
    end

    # This action generates the WSDL for defined SOAP methods.
    def _generate_wsdl
      @map       = self.class.soap_actions
      @namespace = namespace
      @name      = controller_path.gsub('/', '_')

      render :template => 'wash_with_soap/wsdl'
    end

    # Render a SOAP response.
    def _render_soap(result, options)
      @namespace  = namespace
      @operation  = soap_action = request.env['wash_out.soap_action']
      action_spec = self.class.soap_actions[soap_action][:out].clone

      result = { 'value' => result } unless result.is_a? Hash
      result = HashWithIndifferentAccess.new(result)

      inject = lambda {|data, source_spec|
        spec = source_spec.clone

        spec.each_with_index do |param, i|
          if param.struct? && !param.multiplied
            spec[i].map = inject.call(data[param.name], param.map)
          elsif param.struct? && param.multiplied
            spec[i].map = data[param.name].map{|e| inject.call(e, param.map)}
          else
            spec[i] = param.flat_copy
            spec[i].value = data[param.name]
          end
        end

        return spec
      }

      render :template => 'wash_with_soap/response',
             :locals => { :result => inject.call(result, action_spec) }
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
