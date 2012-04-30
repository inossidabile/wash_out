module WashOut
  class Engine < ::Rails::Engine
    class << self
      attr_accessor :namespace
      attr_accessor :snakecase, :snakecase_args, :snakecase_return
    end

    self.namespace = 'urn:WashOut'
    self.snakecase = nil

    self.snakecase_args   = false
    self.snakecase_return = false

    config.wash_out = ActiveSupport::OrderedOptions.new

    initializer "wash_out.configuration" do |app|
      app.config.wash_out.each do |key, value|
        self.class.send "#{key}=", value
      end

      unless self.class.snakecase.nil?
        raise "Usage of wash_out.snakecase is deprecated. You should use wash_out.snakecase_args and wash_out.snakecase_return"
      end
    end
  end
end