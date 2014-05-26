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
          if soap_config.camelize_wsdl.to_s == 'lower'
            options[:to] ||= action.to_s
            action         = action.to_s.camelize(:lower)
          elsif soap_config.camelize_wsdl
            options[:to] ||= action.to_s
            action         = action.to_s.camelize
          end

        end

        default_response_tag = soap_config.camelize_wsdl ? 'Response' : '_response'
        default_response_tag = action+default_response_tag

        #check only hash, , symbol and strings allowed
        # array can only have strings or symbols and size == 1
        #hash can\t have nested hashes
        
        check_soap_args(options[:args])
        check_soap_args(options[:returns])
        
        self.soap_actions[action] = options.merge(
          :in           => WashOut::Param.parse_def(soap_config, options[:args]),
          :out          => WashOut::Param.parse_def(soap_config, options[:return]),
          :to           => options[:to] || action,
          :response_tag => options[:response_tag] || default_response_tag
        )
      end
      
      
      def check_array_format(value)
        if value.size > 1
          raise RuntimeError, "Arrays can only have one value #{value.inspect}"
        else 
          if value[0].is_a?(Hash)
            raise RuntimeError, "Arrays cannot have hashes.Please consider using classified type for this: #{value[0].inspect}"
          end
        end
      end
      
      def check_virtus_model_format(value)
        if  value.ancestors.include?(WashOut::Type) ||   value.class.ancestors.include?(WashOut::Type) 
          elem =  value.attribute_set.detect {|elem|  elem.primitive.to_s.downcase == "hash" }
          raise RuntimeError, "Please consider using classified type for this: #{elem.inspect}" if elem.present?
        end
      end
      
      def check_soap_args(args)
        if (args.is_a?(Hash))
          args.each do |key, value|   
            if value.is_a?(Hash)
              raise RuntimeError, "Please consider using classified type for this: #{value.inspect}"
            elsif value.is_a?(Array) 
              check_array_format(value)
            else
              check_virtus_model_format(value)
            end
          end
        elsif args.is_a?(Array) 
          check_array_format(args)
        else
          check_virtus_model_format(args)
        end
      end
      
      
    end

    included do
      include WashOut::Configurable
      include WashOut::Dispatcher
      include WashOut::WsseParams
      self.soap_actions = {}
    end
  end
end
