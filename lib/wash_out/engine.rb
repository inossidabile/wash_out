module WashOut
  class Engine < ::Rails::Engine
    class << self
      attr_accessor :namespace
      attr_accessor :snakecase
    end

    self.namespace = 'urn:WashOut'
    self.snakecase = false

    config.wash_out = ActiveSupport::OrderedOptions.new

    initializer "wash_out.configuration" do |app|
      app.config.wash_out.each do |key, value|
        self.class.send "#{key}=", value
      end
    end
  end
end