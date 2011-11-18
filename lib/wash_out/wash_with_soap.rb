module WashOut
  module WashWithSoap
    module ClassMethods
      attr_accessor :wsdl_methods

      def wsdl_method(method, options={})
        try_param = ->(opts) do
          Hash[*Array(opts).map { |name, opt|
            [ name,
              if opt.is_a? WashOut::Param
                opt
              else
                WashOut::Param.new(name, opt)
              end
            ]
          }]
        end

        self.wsdl_methods[method.to_s] = {
          :in  => try_param.(options[:args]),
          :out => try_param.(options[:return])
        }
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, WashOut::Dispatcher
      base.wsdl_methods = {}
    end
  end
end