require 'bundler/setup'
require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :console do
  require "action_controller/railtie"
  require "rails/test_unit/railtie"
  Bundler.require
  binding.pry
end