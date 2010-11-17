require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/cubicle/version', __FILE__)

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
end

task :default => :test

desc 'Builds the gem'
task :build do
  sh "gem build cubicle.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install cubicle-#{Cubicle::VERSION}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{Cubicle::VERSION}"
  sh "git push origin master"
  sh "git push origin v#{Cubicle::VERSION}"
  sh "gem push cubicle-#{Cubicle::VERSION}.gem"
end
