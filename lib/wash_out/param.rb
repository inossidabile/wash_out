module WashOut
  class Param
    attr_accessor :name
    attr_accessor :map
    attr_accessor :type
    attr_accessor :multiplied
    
    attr_accessor :value
    def value
      struct? ? map : @value
    end
    
    def [](key)
      map[key]
    end
    
    def struct?
      type == 'struct'
    end
    
    def namespaced_type
      struct? ? "typens:#{name}" : "xsd:#{type}"
    end
    
    def initialize(name, type, multiplied = false)
      type ||= {}
      
      @name       = name.to_s
      @map        = {}
      @multiplied = multiplied

      if type.is_a?(Hash)
        @type = 'struct'
        
        type.each do |name, type|
          if type.is_a?(Array)
            @map[name.to_s] = Param.new(name, type[0], true) 
          else
            @map[name.to_s] = Param.new(name, type)
          end
        end
      else
        @type = type.to_s
      end
    end
    
    def load(data)
      if struct?
        map.each do |name, param|
          param.load(data[name] || data[name.to_sym])
        end
      else
        @value = Param.convert_scalar(data, type)
      end
      
      self
    end
    
    def self.convert_scalar(data, type)
      return data.to_s    if type == 'string'
      return data.to_i    if type == 'integer'
      return data.to_f    if type == 'double'
      return data.to_bool if type == 'boolean'
    end
  end
end