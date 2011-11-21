module WashOut
  class Param
    attr_accessor :name
    attr_accessor :map
    attr_accessor :type
    attr_accessor :multiplied

    # Defines a WSDL parameter with name +name+ and type specifier +type+.
    # The type specifier format is described in #parse_def.
    def initialize(name, type, multiplied = false)
      type ||= {}

      @name       = name.to_s
      @map        = {}
      @multiplied = multiplied

      if type.is_a?(Symbol)
        @type = type.to_s
      else
        @type = 'struct'
        @map  = self.class.parse_def(type)
      end
    end

    # Converts a generic externally derived Ruby value, such as String or
    # Hash, to a native Ruby object according to the definition of this type.
    def load(data)
      if struct?
        data = ActiveSupport::HashWithIndifferentAccess.new(data)
        @map.map do |param|
          param.load(data[param.name])
        end
      else
        case type
          when 'string';  data.to_s
          when 'integer'; data.to_i
          when 'double';  data.to_f
          when 'boolean'; data == 'true' # Is this bad?
          else raise RuntimeError, "Invalid WashOut simple type: #{type}"
        end
      end
    end

    # Checks if this Param defines a complex type.
    def struct?
      type == 'struct'
    end

    # Returns a WSDL namespaced identifier for this type.
    def namespaced_type
      struct? ? "typens:#{name}" : "xsd:#{type}"
    end

    # Parses a +definition+. The format of the definition is best described
    # by the following BNF-like grammar.
    #
    # simple_type := :string | :integer | :double | :boolean
    # nested_type := type_hash | simple_type | WashOut::Param instance
    # type_hash   := { :parameter_name => nested_type, ... }
    # definition  := [ WashOut::Param, ... ] |
    #                type_hash |
    #                simple_type
    #
    # If a simple type is passed as the +definition+, a single Param is returned
    # with the +name+ set to "value".
    # If a WashOut::Param instance is passed as a +nested_type+, the corresponding
    # +:parameter_name+ is ignored.
    #
    # This function returns an array of WashOut::Param objects.
    def self.parse_def(definition)
      definition = { :value => definition } if definition.is_a? Symbol

      if definition.is_a? Hash
        definition.map do |name, opt|
          if opt.is_a? WashOut::Param
            opt
          else
            WashOut::Param.new(name, opt)
          end
        end
      else
        definition.to_a
      end
    end
  end
end
