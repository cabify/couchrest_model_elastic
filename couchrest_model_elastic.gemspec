# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'couchrest_model_elastic/version'

Gem::Specification.new do |spec|
  spec.name          = 'couchrest_model_elastic'
  spec.version       = CouchrestModelElastic::VERSION
  spec.authors       = ['awilliams']
  spec.email         = ['adam@cabify.com']
  spec.description   = %q{Integrates Elasticsearch with couchrest_model gem}
  spec.summary       = %q{Allows Elasticsearch indexing of any CouchRest::Model::Base object and easy creation of search methods}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'couchrest_model'
  spec.add_dependency 'elasticsearch'
  spec.add_dependency 'jbuilder'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
end
