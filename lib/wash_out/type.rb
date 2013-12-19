module WashOut
  class Type

    def self.type_name(value)
      @param_type_name = value.to_s
    end

    def self.map(value)
      raise RuntimeError, "Wrong definition: #{value.inspect}" unless value.is_a?(Hash)
      @param_map = value
    end

    def self.wash_out_param_map
      @param_map
    end

    def self.wash_out_param_name(soap_config = nil)
      soap_config ||= WashOut::SoapConfig.new({})
      @param_type_name ||= name.underscore.gsub '/', '.'

      if soap_config.camelize_wsdl.to_s == 'lower'
        @param_type_name = @param_type_name.camelize(:lower)
      elsif soap_config.camelize_wsdl
        @param_type_name = @param_type_name.camelize
      end
      @param_type_name
    end
  end
end
