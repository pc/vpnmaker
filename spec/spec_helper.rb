require 'vpnmaker'
require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs: true
end

def vpn_root(name=nil)
  return "/vpns" if name.nil?
  "/vpns/#{name}.vpn"
end

def vpn_data(name)
  "#{vpn_root(name)}/#{name}_data"
end

def key_props
  { :key_properties => {
      :country => "US",
      :province => "CA",
      :city => "San Francisco",
      :organization => "Entropy",
      :email => "test@example.com"
    }
  }
end