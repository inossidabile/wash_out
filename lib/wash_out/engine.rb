module WashOut
  class Engine < ::Rails::Engine
    config.wash_out = ActiveSupport::OrderedOptions.new
    initializer "wash_out.configuration" do |app|
      if app.config.wash_out[:catch_xml_errors]
        app.config.middleware.insert_after(ActionDispatch::ShowExceptions, WashOut::Middleware)
      end
    end

  end
end
