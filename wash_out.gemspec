Gem::Specification.new do |s|
  s.name        = "wash_out"
  s.version     = "0.1"
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Dead simple Rails 3 SOAP server library"
  s.email       = "boris@roundlake.ru"
  s.homepage    = "http://github.com/roundlake/wash_out"
  s.description = "Dead simple Rails 3 SOAP server library"
  s.authors     = ['Boris Staal', 'Peter Zotov']

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_development_dependency("rspec-rails")
  s.add_development_dependency("appraisal")
  s.add_development_dependency("sqlite3")
end
