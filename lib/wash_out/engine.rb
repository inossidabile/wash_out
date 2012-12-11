module WashOut
  class Engine < ::Rails::Engine
    class << self
      attr_accessor :namespace
      attr_accessor :snakecase, :camelize_output
      attr_accessor :snakecase_input, :camelize_wsdl
      attr_accessor :wsse_username, :wsse_password
      attr_accessor :catch_xml_errors
    end

    self.namespace = 'urn:WashOut'
    self.snakecase = nil

    self.snakecase_input = false
    self.camelize_wsdl   = false

    self.wsse_username = nil
    self.wsse_password = nil

    config.wash_out = ActiveSupport::OrderedOptions.new

    initializer "wash_out.configuration" do |app|
      app.config.wash_out.each do |key, value|
        self.class.send "#{key}=", value
      end

      app.config.wash_out.catch_xml_errors ||= false

      unless self.class.snakecase.nil?
        raise "Usage of wash_out.snakecase is deprecated. You should use wash_out.snakecase_input and wash_out.camelize_wsdl"
      end

      unless self.class.camelize_output.nil?
        raise "Usage of wash_out.camelize_output is deprecated. You should use wash_out.camelize_wsdl option instead"
      end

      if self.class.catch_xml_errors
        app.config.middleware.insert_after 'ActionDispatch::ShowExceptions', WashOut::Middleware
      end
    end
  end
end
