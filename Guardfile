# More info at https://github.com/guard/guard#readme

# Could be changed to whatever you want.
#  See: https://github.com/guard/guard#notification
notification :off

guard 'rspec' do
  watch %r{^spec/.+_spec\.rb$}
  watch %r{lib/wash_out/(dispatcher|param|type).rb} do |m|
    "spec/wash_out/#{m[1]}_spec.rb"
  end
  watch %r{lib/} do 'spec' end
end

# vim:ft=ruby
