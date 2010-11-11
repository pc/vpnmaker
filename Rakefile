require 'highline/import'
require File.join(File.dirname(__FILE__), 'vpnmaker')

def get_arg(argname, echo=true)
  return ENV[argname] if ENV[argname]
  ask("Value for #{argname}?") { |q| q.echo = false unless echo }
end

namespace :config do
  desc 'Generate server config'
  task :server => :environment do
    puts $manager.config_generator.server
  end

  desc 'Generate client config'
  task :client => :environment do
    username = get_arg('username')
    puts $manager.config_generator.client($manager.user(username))
  end
end

namespace :user do
  desc 'Create a new user'
  task :create => :environment do
    cn = get_arg('cn')
    name = get_arg('name')
    email = get_arg('email')
    password = get_arg('password', false)
    confirm_password = get_arg('confirm_password', false)
    raise ArgumentError.new("Password mismatch") unless password == confirm_password

    if password.length > 0
      $manager.create_user(cn, name, email, password)
    else
      $manager.create_user(cn, name, email)
    end
  end
end

# Set up environment
task :environment do
  vpndir = get_arg('vpndir')
  $manager = VPNMaker::Manager.new(vpndir)
end
