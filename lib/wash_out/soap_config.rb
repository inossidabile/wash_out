module WashOut
  require 'forwardable'
  # Configuration options for {Client}, defaulting to values
  # in {Default}
  class SoapConfig
    extend Forwardable
    DEFAULT_CONFIG = {
      parser: :rexml,
      namespace: 'urn:WashOut',
      wsdl_style: 'rpc',
      snakecase_input: false,
      camelize_wsdl: false,
      catch_xml_errors: false,
      wsse_username: nil,
      wsse_password: nil,
      wsse_auth_callback: nil,
      soap_action_routing: true,
      service_name: 'service'
    }

    attr_reader :config
    def_delegators :@config, :[], :[]=, :sort


    # The keys allowed
    def self.keys
      @keys ||= config.keys
    end

    def self.config
      DEFAULT_CONFIG
    end

    def self.soap_accessor(*syms)
      syms.each do |sym|

        unless sym =~ /^[_A-Za-z]\w*$/
          raise NameError.new("invalid class attribute name: #{sym}")
        end
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          unless defined? @#{sym}
            @#{sym} = nil
          end

          def #{sym}
            @#{sym}
          end

          def #{sym}=(obj)
            @#{sym} = obj
          end
        EOS
      end
    end

    soap_accessor(*WashOut::SoapConfig.keys)

    def initialize(options = {})
      @config = {}
      options.reverse_merge!(engine_config) if engine_config
      options.reverse_merge!(DEFAULT_CONFIG)
      configure options
    end

    def default?
      DEFAULT_CONFIG.sort == config.sort
    end

    def configure(options = {})
      @config.merge! validate_config!(options)

      config.each do |key,value|
        send("#{key}=", value)
      end
    end

    private

      def engine_config
        @engine_config ||= WashOut::Engine.config.wash_out
      end

      def validate_config!(options = {})
        rejected_keys = options.keys.reject do |key|
          WashOut::SoapConfig.keys.include?(key)
        end

        if rejected_keys.any?
          raise "The following keys are not allows: #{rejected_keys}\n Did you intend for one of the following? #{WashOut::SoapConfig.keys}"
        end
        options
      end
  end
end
