module WashOut
  module WashWithSoap
    def self.included(base)
      
      base.class_eval do
        class <<self
          attr_accessor :wash_with_soap_map
        end
        
        def self.wash_with_soap(map)
          map.each do |method, params|
            params[:in]  = WashOut::Param.new(method, map[method][:in]) unless map[method][:in].is_a?(Param)
            params[:out] = WashOut::Param.new("#{method}_responce", map[method][:out]) unless map[method][:out].is_a?(Param)
          end
          
          self.wash_with_soap_map = map
          
          include WashOut::Dispatcher
        end
      end
      
    end
  end
end