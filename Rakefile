require 'bundler/setup'
require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Default: run the unit tests."
task :default => [:all]

task :console do
  require "action_controller/railtie"
  require "rails/test_unit/railtie"
  Bundler.require
  binding.pry
end

desc 'Test the plugin under all supported Rails versions.'
task :all => ["appraisal:install"] do |t|
  exec('rake appraisal spec')
end
