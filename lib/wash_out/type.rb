module WashOut
  class Type
    class <<self
      def type_name(value)
        @param_type_name = value.to_s
      end

      def map(value)
        raise RuntimeError, "Wrong definition: #{value.inspect}" unless value.is_a?(Hash)
        @param_map = value
      end

      def wash_out_param_map
        @param_map
      end

      def wash_out_param_name(soap_config = nil)
        WashOut.normalize(@param_type_name || name.underscore.gsub('/', '.'), soap_config)
      end
    end
  end
end
