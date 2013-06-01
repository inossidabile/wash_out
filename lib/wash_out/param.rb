module WashOut
  class Param
    attr_accessor :raw_name
    attr_accessor :name
    attr_accessor :map
    attr_accessor :type
    attr_accessor :multiplied
    attr_accessor :value
    attr_accessor :source_class

    # Defines a WSDL parameter with name +name+ and type specifier +type+.
    # The type specifier format is described in #parse_def.
    def initialize(name, type, multiplied = false)
      type ||= {}

      @name       = name.to_s
      @raw_name   = name.to_s
      @map        = {}
      @multiplied = multiplied

      if WashOut::Engine.camelize_wsdl.to_s == 'lower'
        @name = @name.camelize(:lower)
      elsif WashOut::Engine.camelize_wsdl
        @name = @name.camelize
      end

      if type.is_a?(Symbol)
        @type = type.to_s
      elsif type.is_a?(Class)
        @type         = 'struct'
        @map          = self.class.parse_def(type.wash_out_param_map)
        @source_class = type
      else
        @type = 'struct'
        @map  = self.class.parse_def(type)
      end
    end

    # Converts a generic externally derived Ruby value, such as String or
    # Hash, to a native Ruby object according to the definition of this type.
    def load(data, key)
      if !data.has_key? key
        raise WashOut::Dispatcher::SOAPError, "Required SOAP parameter '#{key}' is missing"
      end

      data = data[key]
      data = [data] if @multiplied && !data.is_a?(Array)

      if struct?
        data ||= {}
        if @multiplied
          data.map do |x|
            map_struct x do |param, data, elem|
              param.load(data, elem)
            end
          end
        else
          map_struct data do |param, data, elem|
            param.load(data, elem)
          end
        end
      else
        operation = case type
          when 'string';    :to_s
          when 'integer';   :to_i
          when 'double';    :to_f
          when 'boolean';   lambda{|data| data === "0" ? false : !!data}
          when 'date';      :to_date
          when 'datetime';  :to_datetime
          when 'time';      :to_time
          else raise RuntimeError, "Invalid WashOut simple type: #{type}"
        end

        begin
          if data.nil?
            data
          elsif @multiplied
            return data.map{|x| x.send(operation)} if operation.is_a?(Symbol)
            return data.map{|x| operation.call(x)} if operation.is_a?(Proc)
          elsif operation.is_a? Symbol
            data.send(operation)
          else
            operation.call(data)
          end
        rescue
          raise WashOut::Dispatcher::SOAPError, "Invalid SOAP parameter '#{key}' format"
        end
      end
    end

    # Checks if this Param defines a complex type.
    def struct?
      type == 'struct'
    end

    def classified?
      !source_class.nil?
    end

    def basic_type
      return name unless classified?
      return source_class.wash_out_param_name
    end

    def xsd_type
      return 'int' if type.to_s == 'integer'
      return 'dateTime' if type.to_s == 'datetime'
      return type
    end

    # Returns a WSDL namespaced identifier for this type.
    def namespaced_type
      struct? ? "tns:#{basic_type}" : "xsd:#{xsd_type}"
    end

    # Parses a +definition+. The format of the definition is best described
    # by the following BNF-like grammar.
    #
    #   simple_type := :string | :integer | :double | :boolean
    #   nested_type := type_hash | simple_type | WashOut::Param instance
    #   type_hash   := { :parameter_name => nested_type, ... }
    #   definition  := [ WashOut::Param, ... ] |
    #                  type_hash |
    #                  simple_type
    #
    # If a simple type is passed as the +definition+, a single Param is returned
    # with the +name+ set to "value".
    # If a WashOut::Param instance is passed as a +nested_type+, the corresponding
    # +:parameter_name+ is ignored.
    #
    # This function returns an array of WashOut::Param objects.
    def self.parse_def(definition)
      raise RuntimeError, "[] should not be used in your params. Use nil if you want to mark empty set." if definition == []
      return [] if definition == nil

      if definition.is_a?(Class) && definition.ancestors.include?(WashOut::Type)
        definition = definition.wash_out_param_map
      end

      if [Array, Symbol].include?(definition.class)
        definition = { :value => definition }
      end

      if definition.is_a? Hash
        definition.map do |name, opt|
          if opt.is_a? WashOut::Param
            opt
          elsif opt.is_a? Array
            WashOut::Param.new(name, opt[0], true)
          else
            WashOut::Param.new(name, opt)
          end
        end
      else
        raise RuntimeError, "Wrong definition: #{definition.inspect}"
      end
    end

    def flat_copy
      copy = self.class.new(@name, @type.to_sym, @multiplied)
      copy.raw_name = raw_name
      copy
    end

    private

    # Used to load an entire structure.
    def map_struct(data)
      unless data.is_a?(Hash)
        raise WashOut::Dispatcher::SOAPError, "SOAP message structure is broken"
      end

      data   = data.with_indifferent_access
      struct = {}.with_indifferent_access

      # RUBY18 Enumerable#each_with_object is better, but 1.9 only.
      @map.map do |param|
        if data.has_key? param.raw_name
          struct[param.raw_name] = yield param, data, param.raw_name
        end
      end

      struct
    end
  end
end
