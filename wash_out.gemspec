SPEC = Gem::Specification.new do |s|
  s.name        = "wash_out"
  s.version     = "0.1"
  s.platform    = Gem::Platform::RUBY  
  s.summary     = "Dead simple Rails 3 SOAP server library"
  s.email       = "boris@roundlake.ru"
  s.homepage    = "http://github.com/roundlake/wash_out"
  s.description = "Dead simple Rails 3 SOAP server library"
  s.authors     = ['Boris Staal']

  s.add_dependency "crack"

  s.has_rdoc = false # disable rdoc generation until we've got more
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
end