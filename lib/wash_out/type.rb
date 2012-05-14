module WashOut
  class Type
    def self.type_name(value)
      @param_type_name = value
    end

    def self.map(value)
      raise RuntimeError, "Wrong definition: #{value.inspect}" unless value.is_a?(Hash)
      @param_map = value
    end

    def self.wash_out_param_map
      @param_map
    end

    def self.wash_out_param_name
      return name.underscore unless @param_type_name
      @param_type_name
    end
  end
end