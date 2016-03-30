module WashOut
  # The WashOut::Dispatcher module should be included in a controller acting
  # as a SOAP endpoint. It includes actions for generating WSDL and handling
  # SOAP requests.
  module Dispatcher
    # A SOAPError exception can be raised to return a correct SOAP error
    # response.
    class SOAPError < Exception
      attr_accessor :code
      def initialize(message, code=nil)
        super(message)
        @code = code
      end
    end

    class ProgrammerError < Exception; end

    def _authenticate_wsse

      begin
        xml_security   = request.env['wash_out.soap_data'].values_at(:envelope, :Envelope).compact.first
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
      @_params = _load_params action_spec[:in],
        _strip_empty_nodes(action_spec[:in], xml_data)
    end

    def _strip_empty_nodes(params, hash)
      hash.keys.each do |key|
        param = params.detect { |a| a.raw_name.to_s == key.to_s }
        next if !(param && hash[key].is_a?(Hash))

        value = hash[key].delete_if do |k, _|
          k.to_s[0] == '@' && !param.map.detect { |a| a.raw_name.to_s == k.to_s }
        end

        if value.length > 0
          hash[key] = _strip_empty_nodes param.map, value
        else
          hash[key] = nil
        end
      end

      hash
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

      render :template => "wash_out/#{soap_config.wsdl_style}/wsdl", :layout => false,
             :content_type => 'text/xml'
    end

    # Render a SOAP response.
    def _render_soap(result, options)
      @namespace   = soap_config.namespace
      @operation   = soap_action = request.env['wash_out.soap_action']
      @action_spec = self.class.soap_actions[soap_action]

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

      render :template => "wash_out/#{soap_config.wsdl_style}/response",
             :layout => false,
             :locals => { :result => inject.call(result, @action_spec[:out]) },
             :content_type => 'text/xml'
    end

    # This action is a fallback for all undefined SOAP actions.
    def _invalid_action
      render_soap_error("Cannot find SOAP action mapping for #{request.env['wash_out.soap_action']}")
    end

    def _catch_soap_errors
      yield
    rescue SOAPError => error
      render_soap_error(error.message, error.code)
    end

    # Render a SOAP error response.
    #
    # Rails do not support sequental rescue_from handling, that is, rescuing an
    # exception from a rescue_from handler. Hence this function is a public API.
    def render_soap_error(message, code=nil)
      render :template => "wash_out/#{soap_config.wsdl_style}/error", :status => 500,
             :layout => false,
             :locals => { :error_message => message, :error_code => (code || 'Server') },
             :content_type => 'text/xml'
    end

    def self.included(controller)
      entity = if defined?(Rails::VERSION::MAJOR) && (Rails::VERSION::MAJOR >= 4)
        'action'
      else
        'filter' 
      end

      controller.send :"around_#{entity}", :_catch_soap_errors
      controller.send :helper, :wash_out
      controller.send :"before_#{entity}", :_authenticate_wsse,     :except => [
        :_generate_wsdl, :_invalid_action ]
      controller.send :"before_#{entity}", :_map_soap_parameters,   :except => [
        :_generate_wsdl, :_invalid_action ]
      controller.send :"skip_before_#{entity}", :verify_authenticity_token
    end

    def self.deep_select(collection, result = [])
      is_id = lambda { |v| v.is_a?(Hash) && v.has_key?(:@id) }
      values = collection.respond_to?(:values) ? collection.values : collection
      result += values.select(&is_id)

      values.each do |value|
        if value.is_a?(Hash) || value.is_a?(Array)
          result = deep_select(value, result)
        end
      end

      result
    end

    def self.deep_replace_href(hash, replace)
      hash.each do |key, value|
        if value.respond_to?(:has_key?) && value.has_key?(:@href)
          hash[key] = replace[value[:@href]]
          hash = deep_replace_href(hash, replace) if hash.is_a?(Hash)
        elsif key == :@href
          hash = replace[value]
        end

        if hash[key].is_a?(Hash)
          hash[key] = deep_replace_href(hash[key], replace)
        elsif hash[key].is_a?(Array)
          hash[key] = hash[key].map do |v|
            v.is_a?(Hash) ? deep_replace_href(v, replace) : v
          end
        end
      end

      hash
    end

    private
    def action_spec
      self.class.soap_actions[soap_action]
    end

    def request_input_tag
      action_spec[:request_tag]
    end

    def soap_action
      request.env['wash_out.soap_action']
    end

    def xml_data
      xml_data = request.env['wash_out.soap_data'].values_at(:envelope, :Envelope).compact.first
      xml_data = xml_data.values_at(:body, :Body).compact.first || {}
      return xml_data if soap_config.wsdl_style == "document"
      xml_data = xml_data.values_at(soap_action.underscore.to_sym, soap_action.to_sym, request_input_tag.to_sym).compact.first || {}
    end

  end
end
