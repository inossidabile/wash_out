module WashOut
  class SoapActions
    extend Forwardable
    def_delegators :@soap_actions, :[], :[]=, :sort, :each, :keys, :invert, :select

    def initialize(options = {})
      @soap_actions = options
    end

    def fetch(action)
      action_spec = self[action]

      unless action_spec
        action_spec = self.invert.select{|k,v| k[:raw_action] == action }
        action_spec = action_spec.keys[0] if action_spec.is_a?(Hash)
      end

      action_spec
    end
  end
end
