# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "outright_cap/version"

Gem::Specification.new do |s|
  s.name        = "outright_cap"
  s.version     = OutrightCap::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["bob"]
  s.email       = ["bob@example.com"]
  s.homepage    = ""
  s.summary     = %q{Write a gem summary}
  s.description = %q{Write a gem description}

  s.rubyforge_project = "outright_cap"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency "rake"
end
