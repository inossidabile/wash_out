module WashOut
  module SOAP
    module ClassMethods
      attr_accessor :soap_actions

      # Define a SOAP action +action+. The function has two required +options+:
      # :args and :return. Each is a type +definition+ of format described in
      # WashOut::Param#parse_def.
      #
      # An optional option :to can be passed to allow for names of SOAP actions
      # which are not valid Ruby function names.
      def soap_action(action, options={})
        self.soap_actions[action.to_s] = {
          :in     => WashOut::Param.parse_def(options[:args]),
          :out    => WashOut::Param.parse_def(options[:return]),
          :to     => options[:to] || action
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
