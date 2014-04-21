require 'vpnmaker'

RSpec.configure do |config|
end

def testfs
  root = File.dirname File.dirname __FILE__
  "#{root}/tmp"
end

def vpn_root(name=nil)
  return "#{testfs}/vpns" if name.nil?
  "#{testfs}/vpns/#{name}.vpn"
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