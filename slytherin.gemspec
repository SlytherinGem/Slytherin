$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "slytherin/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "slytherin"
  s.version     = Slytherin::VERSION
  s.authors     = ["Kaashiwara"]
  s.email       = ["hoge.fuga.kashiwara@gmail.com"]
  s.summary     = "This gem is convenient seeder"
  s.description = "please look description on github"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.4"

  s.add_development_dependency "mysql2"
end
