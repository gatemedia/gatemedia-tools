$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "gatemedia_tools/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "gatemedia_tools"
  s.version     = GatemediaTools::VERSION
  s.authors     = ["Developers @ GateMedia"]
  s.email       = ["dev@gatemedia.ch"]
  s.homepage    = "https://github.com/gatemedia/gatemedia-tools"
  s.summary     = "GateMedia software factory tools"
  s.description = "GateMedia software shared tools"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "colored"
  s.add_dependency "rails", ">= 3.2.14"
end
