# encoding: utf-8
require 'rubygems'
require 'bundler/gem_tasks'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new

task :test => :spec

task :console do
  begin
    # use Pry if it exists
    require 'pry'
    require 'vpnmaker'
    Pry.start
  rescue LoadError
    require 'irb'
    require 'irb/completion'
    require 'vpnmaker'
    ARGV.clear
    IRB.start
  end
end

task :c => :console


require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "vpnmaker #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
