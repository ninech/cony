# -*- encoding: utf-8 -*-
#
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'cony'
  s.version     = File.read(File.expand_path('../VERSION', __FILE__)).strip
  s.authors     = ['nine.ch Development-Team']
  s.email       = ['development@nine.ch']
  s.homepage    = 'http://github.com/ninech/'
  s.license     = 'MIT'
  s.summary     = 'Automatically sends notifications via AMQP when a model has been changed.'
  s.description = 'Automatically sends notifications via AMQP when a model has been changed.'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.0'

  s.add_development_dependency 'rake', '~> 11.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'activerecord', '>= 5.0'
  s.add_development_dependency 'sqlite3'

  s.add_runtime_dependency 'activesupport', '>= 5.0'
  s.add_runtime_dependency 'bunny', '~> 2.6'
end
