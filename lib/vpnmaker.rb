require 'rubygems'

require 'fileutils'
require 'yaml'
require 'erb'
require 'socket'

require 'ipaddr'
require 'ipaddr_extensions'
require 'haml'
require 'slim'

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
  autoload :ConfigGenerator, './vpnmaker/config_generator'
  autoload :KeyDB, './vpnmaker/key_db'
  autoload :KeyConfig, './vpnmaker/key_config'
  autoload :KeyTracker, './vpnmaker/key_tracker'
  autoload :Manager, './vpnmaker/manager'
  autoload :KeyBuilder, './vpnmaker/key_builder'

  def self.generate(*args)
    KeyTracker.generate(args.first, args.last)
  end
end
