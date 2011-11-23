# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require "rspec/rails"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # Remove this line if you don't want RSpec's should and should_not
  # methods or matchers
  require 'rspec/expectations'
  config.include RSpec::Matchers

  # == Mock Framework
  config.mock_with :rspec
end

Savon.configure do |config|
  config.log = false            # disable logging
end

HTTPI.logger = Logger.new(open("/dev/null", 'w'))
HTTPI.adapter = :rack

Dummy::Application.routes.draw do
  wash_out :api
end

def savon_instance
  Savon::Client.new do
    wsdl.document = 'http://dummy/api/wsdl'
  end
end
