module WashOut
  # This class is a Rack middleware used to route SOAP requests to a proper
  # action of a given SOAP controller.
  class Router
    def initialize(controller_name)
      @controller_name = "#{controller_name.to_s}_controller".camelize
    end

    def call(env)
      controller = @controller_name.constantize

      if soap_action = env['HTTP_SOAPACTION']
        # RUBY18 1.8 does not have force_encoding.
        soap_action.force_encoding('UTF-8') if soap_action.respond_to? :force_encoding

        if controller.soap_config.namespace
          namespace = Regexp.escape controller.soap_config.namespace.to_s
          soap_action.gsub!(/^\"(#{namespace}(\/|#)?)?(.*)\"$/, '\3')
        else
          soap_action = soap_action[1...-1]
        end

        env['wash_out.soap_action'] = soap_action
      end

      action_spec = controller.soap_actions[soap_action]
      if action_spec
        action = action_spec[:to]
      else
        action = '_invalid_action'
      end

      controller.action(action).call(env)
    end
  end
end
