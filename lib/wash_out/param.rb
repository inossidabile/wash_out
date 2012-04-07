module WashOut
  class Param
    attr_accessor :name
    attr_accessor :map
    attr_accessor :type
    attr_accessor :multiplied
    attr_accessor :value

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
    def load(data, key)
      if !data.has_key? key
        raise WashOut::Dispatcher::SOAPError, "Required SOAP parameter '#{key}' is missing"
      end

      data = data[key]
      data = [data] if @multiplied && !data.is_a?(Array)

      if struct?
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
          when 'string';  :to_s
          when 'integer'; :to_i
          when 'double';  :to_f
          when 'boolean'; nil # Nori handles that for us
          else raise RuntimeError, "Invalid WashOut simple type: #{type}"
        end

        if operation.nil?
          data
        elsif @multiplied
          data.map{|x| x.send(operation)}
        else
          data.send(operation)
        end
      end
    end

    # Checks if this Param defines a complex type.
    def struct?
      type == 'struct'
    end

    def namespaced_name
      "tns:#{name}"
    end

    # Returns a WSDL namespaced identifier for this type.
    def namespaced_type
      struct? ? namespaced_name : "xsd:#{type}"
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
        raise RuntimeError, "Wrong definition: #{type.inspect}"
      end
    end

    def flat_copy
      copy = self.class.new(@name, @type.to_sym, @multiplied)
    end

    private

    # Used to load an entire structure.
    def map_struct(data)
      data   = data.with_indifferent_access
      struct = {}.with_indifferent_access

      # RUBY18 Enumerable#each_with_object is better, but 1.9 only.
      @map.map do |param|
        if data.has_key? param.name
          struct[param.name] = yield param, data, param.name
        end
      end

      struct
    end
  end
end
