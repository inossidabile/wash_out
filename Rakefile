require 'bundler/setup'
require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task :console do
  require "action_controller/railtie"
  require "rails/test_unit/railtie"
  Bundler.require
  binding.pry
end


desc 'Default: run the unit tests.'
task default: [:all]

desc 'Test the plugin under all supported Rails versions.'
task :all do |_t|
    # this is needed for minitest because it does not support "--pattern" option as Rspec Does
    ENV['SPEC'] = '--name=spec/**{,/*/**}/*_spec.rb'
    exec('bundle exec appraisal install && bundle exec rake appraisal spec')
end
