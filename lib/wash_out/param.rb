module WashOut
  class Param
    attr_accessor :name
    attr_accessor :map
    attr_accessor :type
    attr_accessor :multiplied

    def initialize(name, type, multiplied = false)
      type ||= {}

      @name       = name.to_s
      @map        = {}
      @multiplied = multiplied

      if type.is_a?(Hash)
        @type = 'struct'

        type.each do |subname, subtype|
          if subtype.respond_to? :to_a
            @map[subname.to_s] = Param.new(name, subtype.to_a[0], true)
          else
            @map[subname.to_s] = Param.new(name, subtype)
          end
        end
      else
        @type = type.to_s
      end
    end

    def load(data)
      if struct?
        data = ActiveSupport::HashWithIndifferentAccess.new(data)
        @map.map do |name, param|
          param.load(data[name])
        end
      else
        case type
          when 'string';  data.to_str
          when 'integer'; data.to_int
          when 'double';  data.fo_float
          when 'boolean'; !!data
        end
      end

      self
    end

    def struct?
      type == 'struct'
    end

    def namespaced_type
      struct? ? "typens:#{name}" : "xsd:#{type}"
    end
  end
end
