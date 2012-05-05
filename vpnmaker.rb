require 'rubygems'

require 'fileutils'
require 'yaml'
require 'erb'
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
  autoload :ConfigGenerator, './lib/config_generator'
  autoload :KeyDB, './lib/key_db'
  autoload :KeyConfig, './lib/key_config'
  autoload :KeyTracker, './lib/key_tracker'
  autoload :Manager, './lib/manager'
  autoload :KeyBuilder, './lib/key_builder'
end
