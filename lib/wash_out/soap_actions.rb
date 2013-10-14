module WashOut
  class SoapActions
    extend Forwardable
    def_delegators :@soap_actions, :[], :[]=, :sort, :each, :keys

    def initialize(options = {})
      @soap_actions = options
    end

    def fetch(action)
      action_spec   = @soap_actions[action]
      action_spec ||= @soap_actions.invert.select{|k,v| k[:raw_action] == action }.first.first
      action_spec
    end
  end
end
