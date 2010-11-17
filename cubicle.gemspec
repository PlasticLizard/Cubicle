# encoding: UTF-8
require File.expand_path( "../lib/cubicle/version", __FILE__)

Gem::Specification.new do |s|
  s.name = 'cubicle'
  s.homepage = 'http://github.com/PlasticLizard/cubicle'
  s.summary = 'Pseudo-Multi Dimensional analysis / simplified aggregation for MongoDB in Ruby (NOLAP ;))'
  s.description = "Cubicle provides a dsl and aggregation caching framework for automating the generation, execution and caching of map reduce queries when using MongoDB in Ruby. Cubicle also includes a MongoMapper plugin and a Mongoid pluguin for quickly performing ad-hoc, multi-level group-by queries against a MongoMapper or Mongoid model."
  s.require_path = 'lib'
  s.authors = ['Nathan Stults']
  s.email = ['hereiam@sonic.net']
  s.version = Cubicle::VERSION
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,test}/**/*") + %w[LICENSE.txt README.rdoc]

  s.add_dependency('i18n')
  s.add_dependency('activesupport', '>= 2.3')
  s.add_dependency('bson_ext', '>= 1.1.1')
  s.add_dependency('bson', '>= 1.1.1')
  s.add_dependency('mongo', '>= 1.1.1')
  s.add_dependency('mustache', '>= 0.10.0')

  s.add_development_dependency 'rake'
  s.add_development_dependency('shoulda', '2.10.3')
end
