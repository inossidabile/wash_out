require 'savon'

def mock_controller(&block)
  # You are not expected to understand this.
  class <<(mock = lambda do
    Class.new(ApplicationController) do
      include WashOut::SOAP

      class_exec &block

      def self.controller_path
        "api"
      end

      def default_url_options
        { :controller => 'api' }
      end
    end
  end)
    def invoke
      @self ||= call
    end

    def method_missing(method, *args)
      invoke.send method, *args
    end

    def use!
      $controller = invoke
    end
  end

  mock
end
