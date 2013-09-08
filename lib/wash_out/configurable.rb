module WashOut
  module Configurable
    extend ActiveSupport::Concern

    included do
      cattr_reader :soap_config
      class_variable_set :@@soap_config, WashOut::SoapConfig.new({})
    end

    module ClassMethods

      def soap_config=(obj)

        unless obj.is_a?(Hash)
          raise "Value needs to be a Hash."
        end

        if class_variable_defined?(:@@soap_config)
          class_variable_get(:@@soap_config).configure obj
        else
          class_variable_set :@@soap_config, WashOut::SoapConfig.new(obj)
        end
      end
    end

    def soap_config=(obj)

      unless obj.is_a?(Hash)
        raise "Value needs to be a Hash."
      end

      class_eval do
        if class_variable_defined?(:@@soap_config)
          class_variable_get(:@@soap_config).configure obj
        else
          class_variable_set :@@soap_config, WashOut::SoapConfig.new(obj)
        end
      end
    end
  end
end