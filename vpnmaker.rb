require 'rubygems'
require 'yaml'
require 'erb'

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
  class ConfigFile
    def initialize(spec)
      @spec = YAML.load_file(spec)
    end
    
    def generate
      erb = File.read(__FILE__.path('server.erb'))
      erb.result(HashBinding.from_hash(@spec).binding)
    end
  end
  
  class KeyTracker
    def self.basic_tracker
      {:version => 0, :modified => Time.now, :keys => []}
    end
    
    def self.generate(path)      
      File.open(path, 'w') {|f| f.write(basic_tracker.to_yaml)}
    end
    
    def initialize(path)
      @path = path
      @data = YAML.load_file(path)
    end
    
    def [](k)
      @data[k]
    end
    
    def disk_version
      YAML.load_file(@path)[:version]
    end
    
    def sync
      if disk_version == @data[:version]
        @data[:version] += 1
        File.open(@path, 'w') {|f| f.write(@data.to_yaml)}
      else
        raise "Disk version of #{@path} != loaded version. Try reloading and making your changes again"
      end
    end
  end
  
  class KeyBuilder
    def initialize(tracker, dir)
      @dir = dir
      @tracker = tracker
    end
    
    def cnfpath; "/tmp/openssl-#{$$}.cnf"; end
    
    def opensslvars
      {
        :key_size => 1024,
        :key_dir => @dir,
        :key_country => @tracker[:key_properties][:country],
        :key_province => @tracker[:key_properties][:province],
        :key_city => @tracker[:key_properties][:city],
        :key_org => @tracker[:key_properties][:organization],
        :key_email => @tracker[:key_properties][:email],
        :key_org => @tracker[:key_properties][:organization],
        :key_ou => 'Organization Unit',
        :key_cn => 'Common Name',
        :key_name => 'Name'
      }
    end
    
    def init
      `touch #{@dir}/index.txt`
      `echo 01 > #{@dir}/serial`
    end
    
    def opensslcnf(hash={})
      c = cnfpath
      
      File.open(cnfpath, 'w') do |f|
        f.write(ERB.new(File.read(__FILE__.path('openssl.erb'))).\
          result(HashBinding.from_hash(opensslvars.merge(hash)).binding))
      end
      
      c
    end
    
    # Build Diffie-Hellman parameters for the server side of an SSL/TLS connection.
    def dh(name, keysize=1024)
      `openssl dhparam -out #{@dir}/#{name}.pem #{keysize}`
    end
    
    def ca
      `openssl req -batch -days 3650 -nodes -new -x509 -keyout #{@dir}/ca.key -out #{@dir}/ca.crt -config #{opensslcnf}`
    end
        
    def build_key(file, name, email)
      h = {:key_cn => name, :key_name => name, :key_email => email}
      `openssl req -batch -days 3650 -nodes -new -keyout #{@dir}/#{file}.key -out #{@dir}/#{file}.csr -config #{opensslcnf(h)}`
    	`openssl ca -batch -days 3650 -out #{@dir}/#{file}.crt -in #{@dir}/#{file}.csr -config #{opensslcnf(h)}`
    end
  end
end