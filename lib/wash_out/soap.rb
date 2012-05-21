require 'active_support/concern'

module WashOut
  module SOAP
    extend ActiveSupport::Concern

    module ClassMethods
      attr_accessor :soap_actions

      # Define a SOAP action +action+. The function has two required +options+:
      # :args and :return. Each is a type +definition+ of format described in
      # WashOut::Param#parse_def.
      #
      # An optional option :to can be passed to allow for names of SOAP actions
      # which are not valid Ruby function names.
      def soap_action(action, options={})
        if action.is_a?(Symbol)
          if WashOut::Engine.camelize_wsdl.to_s == 'lower'
            action = action.to_s.camelize(:lower)
          elsif WashOut::Engine.camelize_wsdl
            action = action.to_s.camelize
          end
        else
          action = action.to_s
        end

        self.soap_actions[action] = {
          :in     => WashOut::Param.parse_def(options[:args]),
          :out    => WashOut::Param.parse_def(options[:return]),
          :to     => options[:to] || action
        }
      end
    end

    included do
      include WashOut::Dispatcher
      self.soap_actions = {}
    end
  end
end
