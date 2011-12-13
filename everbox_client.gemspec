# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "everbox_client/version"

Gem::Specification.new do |s|
  s.name        = "everbox_client"
  s.version     = EverboxClient::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["LI Daobing"]
  s.email       = ["lidaobing@gmail.com"]
  s.homepage    = "http://www.everbox.com/"
  s.summary     = %q{EverBox Command Tool}
  s.description = %q{EverBox Command Tool}


  s.files         = Dir.glob("{bin,lib,spec}/**/*") + %w(README.rdoc CHANGELOG.rdoc)
  s.test_files    = Dir.glob("spec/**/*")
  s.executables   = ["everbox"]
  s.require_paths = ["lib"]
  s.extra_rdoc_files = %w(README.rdoc CHANGELOG.rdoc)
  s.add_dependency "oauth"
  s.add_dependency "highline"
  s.add_dependency "json_pure"
  s.add_dependency "rest-client"
  s.add_dependency "launchy"
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rdoc'
end
