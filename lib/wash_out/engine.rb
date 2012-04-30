module WashOut
  class Engine < ::Rails::Engine
    class << self
      attr_accessor :namespace
      attr_accessor :snakecase, :snakecase_input, :camelize_output
    end

    self.namespace = 'urn:WashOut'
    self.snakecase = nil

    self.snakecase_input = false
    self.camelize_output  = false

    config.wash_out = ActiveSupport::OrderedOptions.new

    initializer "wash_out.configuration" do |app|
      app.config.wash_out.each do |key, value|
        self.class.send "#{key}=", value
      end

      unless self.class.snakecase.nil?
        raise "Usage of wash_out.snakecase is deprecated. You should use wash_out.snakecase_inpur and wash_out.camelize_output"
      end
    end
  end
end