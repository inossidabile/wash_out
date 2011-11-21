module WashOut
  module WashWithSoap
    module ClassMethods
      attr_accessor :wsdl_methods

      # Define a SOAP method +method+. The function has two required +options+:
      # :args and :return. Each is a type +definition+ of format described in
      # WashOut::Param#parse_def.
      def wsdl_method(method, options={})
        self.wsdl_methods[method.to_s] = {
          :in  => WashOut::Param.parse_def(options[:args]),
          :out => WashOut::Param.parse_def(options[:return])
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
