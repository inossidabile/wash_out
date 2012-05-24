require 'nori'

module WashOut
  # The WashOut::Dispatcher module should be included in a controller acting
  # as a SOAP endpoint. It includes actions for generating WSDL and handling
  # SOAP requests.
  module Dispatcher
    # A SOAPError exception can be raised to return a correct SOAP error
    # response.
    class SOAPError < Exception; end

    def deep_select(hash, result=[], &blk)
      result += Hash[hash.select(&blk)].values

      hash.each do |key, value|
        result = deep_select(value, result, &blk) if value.is_a? Hash
      end

      result
    end

    def deep_replace_href(hash, replace)
      return replace[hash[:@href]] if hash.has_key?(:@href)

      hash.keys.each do |key, value|
        hash[key] = deep_replace_href(hash[key], replace) if hash[key].is_a?(Hash)
      end

      hash
    end

    # This filter parses the SOAP request and puts it into +params+ array.
    def _parse_soap_parameters
      # Do not interfere with project-space Nori setup
      strip   = Nori.strip_namespaces?
      convert = Nori.convert_tags?
      Nori.strip_namespaces = true

      if WashOut::Engine.snakecase_input
        Nori.convert_tags_to { |tag| tag.snakecase.to_sym }
      else
        Nori.convert_tags_to { |tag| tag.to_sym }
      end

      @_params = Nori.parse(request.body.read)

      references = deep_select(@_params){|k,v| v.is_a?(Hash) && v.has_key?(:@id)}

      unless references.blank?
        replaces = {}; references.each{|r| replaces['#'+r[:@id]] = r}
        @_params = deep_replace_href(@_params, replaces)
      end

      # Reset Nori setup to project-space
      Nori.strip_namespaces = strip
      Nori.convert_tags_to convert
    end

    def _map_soap_parameters
      soap_action = request.env['wash_out.soap_action']
      action_spec = self.class.soap_actions[soap_action]

      xml_data = @_params.values_at(:envelope, :Envelope).compact.first
      xml_data = xml_data.values_at(:body, :Body).compact.first
      xml_data = xml_data.values_at(soap_action.underscore.to_sym, soap_action.to_sym).compact.first || {}

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

      @_params = HashWithIndifferentAccess.new

      action_spec[:in].each do |param|
        key = param.raw_name.to_sym

        if xml_data.has_key? key
          @_params[param.raw_name] = param.load(xml_data, key)
        end
      end
    end

    # This action generates the WSDL for defined SOAP methods.
    def _generate_wsdl
      @map       = self.class.soap_actions
      @namespace = WashOut::Engine.namespace
      @name      = controller_path.gsub('/', '_')

      render :template => 'wash_with_soap/wsdl'
    end

    # Render a SOAP response.
    def _render_soap(result, options)
      @namespace  = WashOut::Engine.namespace
      @operation  = soap_action = request.env['wash_out.soap_action']
      action_spec = self.class.soap_actions[soap_action][:out]

      result = { 'value' => result } unless result.is_a? Hash
      result = HashWithIndifferentAccess.new(result)

      inject = lambda {|data, map|
        result_spec = []

        map.each_with_index do |param, i|
          result_spec[i] = param.flat_copy

          # Inline complex structure
          if param.struct? && !param.multiplied
            result_spec[i].map = inject.call(data[param.raw_name], param.map)

          # Inline array of complex structures
          elsif param.struct? && param.multiplied
            data ||= {} #fallback in case no data is given
            data[param.raw_name] = [] unless data[param.raw_name].is_a?(Array)
            result_spec[i].map = data[param.raw_name].map{|e| inject.call(e, param.map)}

          else
            result_spec[i].value = data[param.raw_name]
          end
        end

        return result_spec
      }

      render :template => 'wash_with_soap/response',
             :locals => { :result => inject.call(result, action_spec) },
             :content_type => 'text/xml'
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
             :locals => { :error_message => message },
             :content_type => 'text/xml'
    end

    private

    def self.included(controller)
      controller.send :rescue_from, SOAPError, :with => :_render_soap_exception
      controller.send :helper, :wash_out
      controller.send :before_filter, :_parse_soap_parameters, :except => [ :_generate_wsdl, :_invalid_action ]
      controller.send :before_filter, :_map_soap_parameters, :except => [ :_generate_wsdl, :_invalid_action ]
    end

    def _render_soap_exception(error)
      render_soap_error(error.message)
    end
  end
end
