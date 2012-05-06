# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "vpnmaker"
  gem.executables = 'vpnmaker'
  gem.homepage = "http://github.com/voipscout/vpnmaker"
  gem.license = "MIT"
  gem.summary = %Q{Makes it easy to manage OpenVPN}
  gem.description = %Q{haml templates and key tracking}
  gem.email = "voipscout@gmail.com"
  gem.authors = ["Voip Scout"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

# require 'rake/testtask'
# Rake::TestTask.new(:test) do |test|
#   test.libs << 'lib' << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
# end

# require 'rcov/rcovtask'
# Rcov::RcovTask.new do |test|
#   test.libs << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
#   test.rcov_opts << '--exclude "gems/*"'
# end

# task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "vpnmaker #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# require 'highline/import'
# require File.join(File.dirname(__FILE__), 'vpnmaker')

# def get_arg(argname, echo=true)
#   return ENV[argname] if ENV[argname]
#   ask("Value for #{argname}?") { |q| q.echo = false unless echo }
# end

# namespace :config do
#   desc 'Generate server config'
#   task :server => :environment do
#     puts $manager.config_generator.server
#   end

#   desc 'Generate client config'
#   task :client => :environment do
#     username = get_arg('username')
#     puts $manager.config_generator.client($manager.user(username))
#   end
# end

# namespace :user do
#   desc 'Create a new user'
#   task :create => :environment do
#     cn = get_arg('cn')
#     name = get_arg('name')
#     email = get_arg('email')
#     password = get_arg('password', false)
#     confirm_password = get_arg('confirm_password', false)
#     raise ArgumentError.new("Password mismatch") unless password == confirm_password

#     if password.length > 0
#       $manager.create_user(cn, name, email, password)
#     else
#       $manager.create_user(cn, name, email)
#     end
#   end
# end

# # Set up environment
# task :environment do
#   vpndir = get_arg('vpndir')
#   $manager = VPNMaker::Manager.new(vpndir)
# end
