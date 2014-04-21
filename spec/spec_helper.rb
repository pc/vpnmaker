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
  "#{vpn_root(name)}/data"
end

def key_props
  { :key_properties => {
      :country => "US",
      :province => "CA",
      :city => "San Francisco",
      :organization => "VPNMaker",
      :email => "test@example.com"
    }
  }
end

def server_props
  { :server => {
      :base_ip => "10.10.10.0",
      :user => "nouser",
      :group => "nogroup",
      :root => "/root/openvpn",
      :log => "/var/log/openvpn.log",
      :host => "example.com",
      :port => "1194"
    }
  }
end