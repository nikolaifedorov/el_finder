# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "el_finder/version"

Gem::Specification.new do |s|
  s.name        = "el_finder"
  s.version     = ElFinder::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nikolai Fedorov"]
  s.email       = ["nikolas.fedorov@gmail.com"]
  s.homepage    = "https://github.com/nikolaifedorov/el_finder"
  s.summary     = %q{elFinder server side connector for Ruby.}
  s.description = %q{Ruby library to provide server side functionality for elFinder.  elFinder is an open-source file manager for web, written in JavaScript using jQuery UI.}

  s.rubyforge_project = "el_finder"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('image_size', '>= 1.0.0')
  s.add_dependency('dropbox-sdk', '>= 1.6.1')
  s.add_dependency('net-ftp-list', '>= 3.2.5')
  s.add_development_dependency('yard', '~> 0.8.1')
  s.add_development_dependency('redcarpet', '~> 2.1.1')
  s.requirements << 'ImageMagick'

end
