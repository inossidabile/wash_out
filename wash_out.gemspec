require File.expand_path("../lib/wash_out/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "wash_out"
  s.version     = WashOut::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Dead simple Rails 3 SOAP server library"
  s.email       = "boris@roundlake.ru"
  s.homepage    = "http://github.com/inossidabile/wash_out/"
  s.description = "Dead simple Rails 3 SOAP server library"
  s.authors     = ['Boris Staal', 'Peter Zotov']

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.post_install_message = <<-EOS
    Please replace `include WashOut::SOAP` with `soap_service`
    in your controllers if you are upgrading from a version before 0.8.5.
  EOS
  s.add_dependency("nori", ">= 2.0.0")
end
