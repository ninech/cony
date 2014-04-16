# -*- encoding: utf-8 -*-
#
$:.push File.expand_path('../lib', __FILE__)
require 'cony/version'

Gem::Specification.new do |s|
  s.name        = 'cony'
  s.version     = Cony::VERSION
  s.authors     = ['Raffael Schmid']
  s.email       = ['raffael@yux.ch']
  s.homepage    = 'http://github.com/ninech/'
  s.license     = 'MIT'
  s.summary     = 'Automatically sends notifications via AMQP when a model has been changed.'
  s.summary     = 'Automatically sends notifications via AMQP when a model has been changed.'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 2.12'

  s.add_runtime_dependency 'activemodel', '>= 3.0'
  s.add_runtime_dependency 'bunny', '~> 1.1.7'
end
