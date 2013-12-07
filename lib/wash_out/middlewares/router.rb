require 'nori'

module WashOut
  module Middlewares
    #
    # This class is a Rack middleware used to route SOAP requests to a proper
    # action of a given SOAP controller.
    #
    # WashOut engine adds routing helper `wash_out` that registeres this middleware
    # as a main responder internally.
    #
    # @see WashOut::Rails::Engine
    #
    class Router
      def initialize(controller_name)
        @controller_name = "#{controller_name.to_s}_controller".camelize
      end

      def parse_soap_action(env)
        return env['wash_out.soap_action'] if env['wash_out.soap_action']

        # SOAPACTION is expected to come in quotes that have to be stripped
        soap_action = env['HTTP_SOAPACTION'].to_s.gsub(/^"(.*)"$/, '\1')

        # Clients can sometimes send empty SOAPACTION to avoid duplication
        # In this cases we have to get it from the body
        if soap_action.blank?
          soap_action = nori.parse(soap_body env)[:Envelope][:Body].keys.first.to_s
        end

        # RUBY18
        soap_action.force_encoding('UTF-8') if soap_action.respond_to? :force_encoding

        # And finally we have to strip namespace from the action name
        if @controller.soap_config.namespace
          namespace = Regexp.escape @controller.soap_config.namespace.to_s
          soap_action.gsub!(/^(#{namespace}(\/|#)?)?([^"]*)$/, '\3')
        end

        env['wash_out.soap_action'] = soap_action
      end

      def parse_soap_parameters(env)
        return env['wash_out.soap_data'] if env['wash_out.soap_data']

        env['wash_out.soap_data'] = nori(@controller.soap_config.snakecase_input).parse(soap_body env)

        # Seeking for in-XML substitutions marked by attribute `id`
        references = self.class.deep_select(env['wash_out.soap_data']) do |k,v|
          v.is_a?(Hash) && v.has_key?(:@id)
        end

        # Replacing the found substitutions with nodes having proper `href` attribute
        unless references.blank?
          replaces = {}
          references.each { |r| replaces['#'+r[:@id]] = r }

          env['wash_out.soap_data'] = self.class.deep_replace_href(env['wash_out.soap_data'], replaces)
        end

        env['wash_out.soap_data']
      end

      #
      # Nori parser builder
      #
      def nori(snakecase=false)
        Nori.new(
          parser:               @controller.soap_config.parser,
          strip_namespaces:     true,
          advanced_typecasting: true,
          convert_tags_to: (
            snakecase ? lambda { |tag| tag.snakecase.to_sym } 
                      : lambda { |tag| tag.to_sym }
          )
        )
      end

      #
      # Universal body accessor working with any Rack server
      #
      def soap_body(env)
        env['rack.input'].respond_to?(:string) ? env['rack.input'].string
                                               : env['rack.input'].read
      end

      def call(env)
        @controller = @controller_name.constantize

        parse_soap_action(env)
        parse_soap_parameters(env)

        action_spec = @controller.soap_actions[env['wash_out.soap_action']]

        if action_spec
          action = action_spec[:to]
        else
          action = '_invalid_action'
        end

        @controller.action(action).call(env)
      end

      #
      # Recursively seeks XML tree for nodes matching given block
      #
      def self.deep_select(hash, result=[], &blk)
        result += Hash[hash.select(&blk)].values

        hash.each do |key, value|
          result = deep_select(value, result, &blk) if value.is_a? Hash
        end

        result
      end

      #
      # Recursively replaces nodes in the tree matching the given
      # map of `href` attributes
      #
      def self.deep_replace_href(hash, replace)
        return replace[hash[:@href]] if hash.has_key?(:@href)

        hash.keys.each do |key, value|
          hash[key] = deep_replace_href(hash[key], replace) if hash[key].is_a?(Hash)
        end

        hash
      end
    end
  end
end