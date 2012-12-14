# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbdaemon/version'

Gem::Specification.new do |gem|
  gem.name          = "rbdaemon"
  gem.version       = RBDaemon::VERSION
  gem.authors       = ["Changli Gao"]
  gem.email         = ["xiaosuo@gmail.com"]
  gem.description   = %q{A daemon library in Ruby}
  gem.summary       = %q{Yet another daemon library in Ruby}
  gem.homepage      = "http://github.com/xiaosuo/rbdaemon"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.license       = 'MIT'
  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake'
end
