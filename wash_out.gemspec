require File.expand_path("../lib/wash_out/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "wash_out"
  s.version     = WashOut::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Dead simple Rails 3 SOAP server library"
  s.email       = "boris@roundlake.ru"
  s.homepage    = "http://roundlake.github.com/wash_out/"
  s.description = "Dead simple Rails 3 SOAP server library"
  s.authors     = ['Boris Staal', 'Peter Zotov']

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency("nori")
  %w(
    savon
    rspec-rails guard guard-rspec rb-inotify rb-fsevent
    appraisal
    tzinfo
    pry-de
  ).each do |dep|
    s.add_development_dependency(dep)
  end
end
