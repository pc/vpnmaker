require File.join(File.dirname(__FILE__), 'vpnmaker')

namespace :config do
  desc 'Generate server config'
  task :server => :environment do
    puts $manager.config_generator.server
  end
end

# Set up environment
task :environment do
  vpndir = ENV['vpndir'] || raise(ArgumentError.new('Must provide vpndir=(dir) argument'))
  $manager = VPNMaker::Manager.new(vpndir)
end
