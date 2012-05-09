require 'rubygems'

require 'gibberish'
# require 'rubyzip'

require 'fileutils'
require 'yaml'
require 'socket'

require 'ipaddr'
require 'ipaddr_extensions'
require 'haml'

require 'pry'

class String
  def path(p)
    File.join(File.dirname(__FILE__), p)
  end
end

class HashBinding < Object
  def self.from_hash(h)
    hb = self.new
    h.each do |k, v|
      hb.instance_variable_set("@#{k}", v)
    end
    hb
  end

  def binding; super; end # normally private
end

module VPNMaker
  path = (File.dirname File.expand_path(__FILE__)) + "/"

  autoload :ConfigGenerator, "#{path}vpnmaker/config_generator"
  autoload :KeyDB, "#{path}vpnmaker/key_db"
  autoload :KeyConfig, "#{path}vpnmaker/key_config"
  autoload :KeyTracker, "#{path}vpnmaker/key_tracker"
  autoload :Manager, "#{path}vpnmaker/manager"
  autoload :KeyBuilder, "#{path}vpnmaker/key_builder"

  def self.generate(*args)
    KeyTracker.generate(args.first, args.last)
  end
end
