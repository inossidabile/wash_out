# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require "simplecov"
SimpleCov.start do
  add_filter 'spec'
  add_group 'Library', 'lib'
  add_group 'App', 'app'

  at_exit do; end
end

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require "rspec/rails"
require "pry"
require "savon"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  require 'rspec/expectations'
  config.include RSpec::Matchers
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.mock_with :rspec
  config.before(:all) do
    WashOut::Engine.config.wash_out = {
      snakecase_input: false,
      camelize_wsdl: false,
      namespace: false
    }
  end

  config.after(:suite) do
    if SimpleCov.running
      silence_stream(STDOUT) do
        SimpleCov::Formatter::HTMLFormatter.new.format(SimpleCov.result)
      end

      SimpleCov::Formatter::SummaryFormatter.new.format(SimpleCov.result)
    end
  end
end

HTTPI.logger = Logger.new(open("/dev/null", 'w'))
HTTPI.adapter = :rack

HTTPI::Adapter::Rack.mount 'app', Dummy::Application
Dummy::Application.routes.draw do
  namespace :route do
    scope module: 'space' do
      wash_out :api
    end
  end
end

def mock_controller(options = {}, &block)
  Object.send :const_set, :Route, Module.new unless defined?(Route)
  Route.send :const_set, :Space, Module.new unless defined?(Route::Space)
  Route::Space.send :remove_const, :ApiController if defined?(Route::Space::ApiController)
  Route::Space.send :const_set, :ApiController, Class.new(ApplicationController) {
    include RSpec::Matchers

    soap_service options.reverse_merge({
      snakecase_input: true,
      camelize_wsdl: true,
      namespace: false
    })
    class_exec &block if block
  }

  ActiveSupport::Dependencies::Reference.instance_variable_get(:'@store').delete('Route::Space::ApiController')
end

unless defined?(silence_stream) # Rails 5
  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? 'NUL:' : '/dev/null')
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
    old_stream.close
  end
end
