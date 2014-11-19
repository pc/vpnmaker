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

  class BuildError < StandardError; end

  ROOT = File.dirname File.dirname __FILE__

  autoload :DataStore,       File.join(ROOT, "lib", "datastore")
  autoload :ConfigGenerator, File.join(ROOT, "lib", "vpnmaker", "config_generator")
  autoload :KeyDB,           File.join(ROOT, "lib", "vpnmaker", "key_db")
  autoload :KeyConfig,       File.join(ROOT, "lib", "vpnmaker", "key_config")
  autoload :KeyTracker,      File.join(ROOT, "lib", "vpnmaker", "key_tracker")
  autoload :Manager,         File.join(ROOT, "lib", "vpnmaker", "manager")
  autoload :KeyBuilder,      File.join(ROOT, "lib", "vpnmaker", "key_builder")

  class << self

    def root
      VPNMaker::ROOT
    end

    def template_path(name=nil)
      return "#{root}/templates" if name.nil?
      "#{root}/templates/#{name}"
    end

    def generate(*args)
      KeyTracker.generate(args.first, args.last)
    end
  end
end
