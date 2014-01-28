module WashOut
  class Type
    include Virtus.model
      
   
    BASIC_TYPES=[
      "string",
      "integer",
      "double",
      "boolean",
      "date",
      "datetime",
      "float",
      "time",
      "int"
    ] 
    
    def self.type_name(value)
      @param_type_name = value.to_s
    end
    
    def self.map
      @param_map = attribute_set.inject({}) {|h, elem| h["#{elem.name}"]= 
        { :primitive => "#{elem.primitive}", 
          :member_type => elem.options[:member_type].nil? ? nil: elem.options[:member_type].primitive, 
          :options => elem.options
        }; h }
    end

    def self.wash_out_param_map
      map
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
