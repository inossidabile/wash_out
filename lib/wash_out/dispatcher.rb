module WashOut
  # The WashOut::Dispatcher module should be included in a controller acting
  # as a SOAP endpoint. It includes actions for generating WSDL and handling
  # SOAP requests.
  module Dispatcher
    # A SOAPError exception can be raised to return a correct SOAP error
    # response.
    class SOAPError < Exception; end
    class ProgrammerError < Exception; end

    def _authenticate_wsse

      begin
        xml_security   = env['wash_out.soap_data'].values_at(:envelope, :Envelope).compact.first
        xml_security   = xml_security.values_at(:header, :Header).compact.first
        xml_security   = xml_security.values_at(:security, :Security).compact.first
        username_token = xml_security.values_at(:username_token, :UsernameToken).compact.first
      rescue
        username_token = nil
      end

      WashOut::Wsse.authenticate soap_config, username_token

      request.env['WSSE_TOKEN'] = username_token.with_indifferent_access unless username_token.blank?
    end

    def _map_soap_parameters

      soap_action = request.env['wash_out.soap_action']
      action_spec = self.class.soap_actions.fetch(soap_action)

      xml_data = env['wash_out.soap_data'].values_at(:envelope, :Envelope).compact.first
      xml_data = xml_data.values_at(:body, :Body).compact.first
      xml_data = xml_data.values_at(soap_action.underscore.to_sym,
                                    soap_action.to_sym).compact.first || {}

      strip_empty_nodes = lambda{|hash|
        hash.keys.each do |key|
          if hash[key].is_a? Hash
            value = hash[key].delete_if{|k, v| key.to_s[0] == '@'}

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
      @_params = _load_params(action_spec[:in], xml_data)
    end

    # Creates the final parameter hash based on the request spec and xml_data from the request
    def _load_params(spec, xml_data)
      params = HashWithIndifferentAccess.new
      spec.each do |param|
        key = param.raw_name.to_sym
        if xml_data.has_key? key
          params[param.raw_name] = param.load(xml_data, key)
        end
      end
      params
    end

    # This action generates the WSDL for defined SOAP methods.
    def _generate_wsdl

      @map       = self.class.soap_actions
      @namespace = soap_config.namespace
      @name      = controller_path.gsub('/', '_')

      render :template => "wash_with_soap/#{soap_config.wsdl_style}/wsdl", :layout => false,
             :content_type => 'text/xml'
    end

    # Render a SOAP response.
    def _render_soap(result, options)
      @namespace   = soap_config.namespace
      @operation   = soap_action = request.env['wash_out.soap_action']
      @action_spec = self.class.soap_actions.fetch(soap_action)

      result = { 'value' => result } unless result.is_a? Hash
      result = HashWithIndifferentAccess.new(result)

      inject = lambda {|data, map|
        result_spec = []
        return result_spec if data.nil?

        map.each_with_index do |param, i|
          result_spec[i] = param.flat_copy

          unless data.is_a?(Hash)
            raise ProgrammerError,
              "SOAP response used #{data.inspect} (which is #{data.class.name}), " +
              "in the context where a Hash with key of '#{param.raw_name}' " +
              "was expected."
          end

          value = data[param.raw_name]

          unless value.nil?
            if param.multiplied && !value.is_a?(Array)
              raise ProgrammerError,
                "SOAP response tried to use '#{value.inspect}' " +
                "(which is of type #{value.class.name}), as the value for " +
                "'#{param.raw_name}' (which expects an Array)."
            end

            # Inline complex structure              {:foo => {bar: ...}}
            if param.struct? && !param.multiplied
              result_spec[i].map = inject.call(value, param.map)

            # Inline array of complex structures    {:foo => [{bar: ...}]}
            elsif param.struct? && param.multiplied
              result_spec[i].map = value.map{|e| inject.call(e, param.map)}

            # Inline scalar                         {:foo => :string}
            else
              result_spec[i].value = value
            end
          end
        end

        return result_spec
      }

      render :template => "wash_with_soap/#{soap_config.wsdl_style}/response",
             :layout => false,
             :locals => { :result => inject.call(result, @action_spec[:out]) },
             :content_type => 'text/xml'
    end

    # This action is a fallback for all undefined SOAP actions.
    def _invalid_action
      render_soap_error("Cannot find SOAP action mapping for #{request.env['wash_out.soap_action']}")
    end

    def _render_soap_exception(error)
      render_soap_error(error.message)
    end

    # Render a SOAP error response.
    #
    # Rails do not support sequental rescue_from handling, that is, rescuing an
    # exception from a rescue_from handler. Hence this function is a public API.
    def render_soap_error(message)
      render :template => "wash_with_soap/#{soap_config.wsdl_style}/error", :status => 500,
             :layout => false,
             :locals => { :error_message => message },
             :content_type => 'text/xml'
    end

    def self.included(controller)
      controller.send :rescue_from, SOAPError, :with => :_render_soap_exception
      controller.send :helper, :wash_out
      controller.send :before_filter, :_authenticate_wsse,     :except => [
        :_generate_wsdl, :_invalid_action ]
      controller.send :before_filter, :_map_soap_parameters,   :except => [
        :_generate_wsdl, :_invalid_action ]
      controller.send :skip_before_filter, :verify_authenticity_token
    end

    def self.deep_select(hash, result=[], &blk)
      result += Hash[hash.select(&blk)].values

      hash.each do |key, value|
        result = deep_select(value, result, &blk) if value.is_a? Hash
      end

      result
    end

    def self.deep_replace_href(hash, replace)
      return replace[hash[:@href]] if hash.has_key?(:@href)

      hash.keys.each do |key, value|
        hash[key] = deep_replace_href(hash[key], replace) if hash[key].is_a?(Hash)
      end

      hash
    end
  end
end
