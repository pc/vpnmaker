require 'rubygems'
require 'yaml'
require 'erb'
require 'socket'

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
  class ConfigGenerator
    def initialize(mgr)
      @mgr = mgr
    end

    def server_conf
      {
        :gen_host => Socket.gethostname
      }.merge(@mgr.config[:server])
    end

    def apply_erb(name, cnf)
      erb = File.read(__FILE__.path(name))
      ERB.new(erb).result(HashBinding.from_hash(cnf).binding)
    end

    def server; apply_erb('server.erb', server_conf); end
    def client; apply_erb('client.erb'); end
  end

  class KeyDB
    def initialize(path)
      @path = path
      @db = File.exists?(path) ? YAML.load_file(path) : {}
      @touched = false
    end

    def [](k); @db[k]; end

    def []=(k, v)
      @db[k] = v
      @db[:modified] = Time.now
      @touched = true
    end

    def touched!
      @touched = true
      @db[:modified] = Time.now
    end


    def datadir; self[:datadir]; end

    def data_path(k)
      File.join(self.datadir, k)
    end

    def dump(k, v, overwrite=false)
      p = data_path(k)
      raise "#{k} already exists" if File.exists?(p) && !overwrite
      File.open(p, 'w') {|f| f.write(v)}
      @touched = true
    end

    def data(k)
      File.exists?(data_path(k)) ? File.read(data_path(k)) : nil
    end

    def disk_version
      File.exists?(@path) ? YAML.load_file(@path)[:version] : 0
    end

    def sync
      if disk_version == @db[:version]
        if @touched
          FileUtils.mkdir_p(self.datadir)
          @db[:version] += 1
          File.open(@path, 'w') {|f| f.write(@db.to_yaml)}
          true
        else
          false
        end
      else
        raise "Disk version of #{@path} (#{disk_version}) != loaded version (#{@db[:version]}). " + \
              "Try reloading and making your changes again."
      end
    end

    def version; @db[:version]; end
  end

  class KeyConfig
    def initialize(path)
      @config = YAML.load_file(path)
    end

    def [](k); @config[k]; end
  end

  class KeyTracker
    attr_reader :builder
    attr_reader :db
    attr_reader :config

    def self.generate(name, path=nil)
      path ||= '/tmp'
      dir = File.join(path, name + '.vpn')

      FileUtils.mkdir_p(dir)
      datadir = File.join(dir, "#{name}_data")
      dbpath = File.join(dir, "#{name}.db.yaml")

      d = KeyDB.new(dbpath)
      d[:version] = 0
      d[:modified] = Time.now
      d[:users] = {}
      d[:datadir] = datadir
      d.sync
    end

    def assert_user(user)
      raise "User doesn't exist: #{user}" unless @db[:users][user]
    end

    def ca; @db[:ca]; end

    def set_ca(key, crt, crl, index, serial)
      raise "CA already set" if @db[:ca]

      @db[:ca] = {:modified => Time.now}
      @db.dump('ca.key', key)
      @db.dump('ca.crt', crt)
      @db.dump('crl.pem', crl)
      @db.dump('index.txt', index)
      @db.dump('serial', serial)
      @db.touched!
      @db.sync
    end

    def set_server_key(key, crt, index, serial)
      raise "Server key already set" if @db[:server]

      @db[:server] = {:modified => Time.now}
      @db.dump('server.key', key)
      @db.dump('server.crt', crt)
      @db.dump('index.txt', index, true)
      @db.dump('serial', serial, true)
      @db.touched!
      @db.sync
    end

    def set_ta_key(ta)
      raise "TA key already set" if @db[:ta]

      @db[:ta] = {:modified => Time.now}
      @db.dump('ta.key', ta)
      @db.touched!
      @db.sync
    end

    def set_dh(dh)
      raise "DH key already set" if @db[:dh]

      @db[:dh] = {:modified => Time.now}
      @db.dump('dh.pem', dh)
      @db.touched!
      @db.sync
    end

    def add_key(user, key, crt, ver)
      @db.dump("#{user}-#{ver}.key", key)
      @db.dump("#{user}-#{ver}.crt", crt)
    end

    def key(user, ver, type)
      @db.data("#{user}-#{ver}.#{type}")
    end

    def add_user(user, name, email, key, crt, p12, index, serial)
      raise "User must be a non-empty string" unless user.is_a?(String) && user.size > 0
      raise "User already exists: #{user}" if @db[:users][user]

      @db[:users][user] = {
        :user => user,
        :name => name,
        :email => email,
        :active_key => 0,
        :revoked => [],
        :modified => Time.now
      }
      @db.dump('serial', serial, true)
      @db.dump('index.txt', index, true)
      add_key(user, key, crt, p12, 0)
      @db.touched!
      @db.sync
    end

    def add_user_key(user, name, email, key, crt, p12, index, serial)
      assert_user(user)

      u = @db[:users][user]
      u[:modified] = Time.now
      u[:active_key] += 1
      add_key(user, key, crt, p12, u[:active_key])

      @db.dump('serial', serial, true)
      @db.dump('index.txt', index, true)

      @db.touched!
      @db.sync
    end

    def user_key_revoked(user, version, crl, index)
      assert_user(user)

      raise "Verison must be an int" unless version.kind_of?(Integer)
      u = @db[:users][user]
      u[:revoked] << version
      u[:modified] = Time.now
      @db.dump('index.txt', index, true)
      @db.dump('crl.pem', crl, true)
      @db.touched!
      @db.sync
    end

    def revoked?(user, version)
      assert_user(user)

      @db[:users][user][:revoked].include?(version)
    end

    def active_key_version(user)
      assert_user(user)

      @db[:users][user][:active_key]
    end

    def user(user)
      assert_user(user)
      @db[:users][user]
    end

    def users; @db[:users]; end

    def initialize(name, dir)
      @db = KeyDB.new(File.join(dir, name + '.db.yaml'))
      @config = KeyConfig.new(File.join(dir, name + '.config.yaml'))
      @builder = KeyBuilder.new(self, @config)
    end
  end

  def self.generate(name, path)
    KeyTracker.generate(name, path)
  end

  class Manager
    attr_reader :tracker

    def self.vpn_name(dir); dir =~ /(^|\/)([^\/\.]+)\.vpn/ ? $2 : nil; end

    def initialize(dir)
      name = self.class.vpn_name(dir)
      @tracker = KeyTracker.new(name, dir)
    end

    def config; @tracker.config; end

    def build_ca; @tracker.builder.build_ca; end
    def build_server
      @tracker.builder.build_server_key
      @tracker.builder.build_ta_key
      @tracker.builder.build_dh_key
    end

    def create_user(user, name, email, pass)
      @tracker.builder.build_key(user, name, email, pass, :add_user)
    end

    def revoke_all(user)
      cur = @tracker.active_key_version(user)
      while cur >= 0
        unless @tracker.revoked?(user, cur)
          @tracker.builder.revoke_key(user, cur)
        end
        cur -= 1
      end
    end

    def regenerate_user(user, pass)
      revoke_all(user)
      u = @tracker.user(user)
      @tracker.builder.build_key(user, u[:name], u[:email], pass, :add_user_key)
    end

    def delete_user(user)
      revoke_all(user)
    end

    def users
      @tracker.users.keys
    end

    def user(user)
      @tracker.user(user)
    end

    def config_generator; ConfigGenerator.new(self); end
  end

  class KeyBuilder
    def initialize(tracker, config)
      @tmpdir = '/tmp/keybuilder'
      clean_tmpdir
      @tracker = tracker
      @config = config
    end

    def clean_tmpdir
      FileUtils.rm_rf(@tmpdir)
      FileUtils.mkdir_p(@tmpdir)
    end

    def cnfpath; "/tmp/openssl-#{$$}.cnf"; end

    def opensslvars
      {
        :key_size => 1024,
        :key_dir => @tmpdir,
        :key_country => @config[:key_properties][:country],
        :key_province => @config[:key_properties][:province],
        :key_city => @config[:key_properties][:city],
        :key_org => @config[:key_properties][:organization],
        :key_email => @config[:key_properties][:email],
        :key_org => @config[:key_properties][:organization],
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
    def build_dh_key(keysize=1024)
      `openssl dhparam -out #{tmppath('dh.pem')} #{keysize}`
      @tracker.set_dh(tmpfile('dh.pem'))
    end

    def ca
      @tracker[:ca]
    end

    def gen_crl
      `openssl ca -gencrl -crldays 3650 -keyfile #{tmppath('ca.key')} -cert #{tmppath('ca.crt')} -out #{tmppath('crl.pem')} -config #{opensslcnf}`
    end

    def build_ca
      index = tmppath('index.txt')

      FileUtils.touch(index)

      `openssl req -batch -days 3650 -nodes -new -x509 -keyout #{@tmpdir}/ca.key -out #{@tmpdir}/ca.crt -config #{opensslcnf}`
      gen_crl
      @tracker.set_ca(tmpfile('ca.key'), tmpfile('ca.crt'), tmpfile('crl.pem'), tmpfile('index.txt'), "01\n")
    end

    def build_server_key
      place_file('ca.crt')
      place_file('ca.key')
      place_file('index.txt')
      place_file('serial')

      `openssl req -batch -days 3650 -nodes -new -keyout #{tmppath('server.key')} -out #{tmppath('server.csr')} -extensions server -config #{opensslcnf}`
      `openssl ca -batch -days 3650 -out #{tmppath('server.crt')} -in #{tmppath('server.csr')} -extensions server -config #{opensslcnf}`

      @tracker.set_server_key(tmpfile('server.key'), tmpfile('server.crt'), tmpfile('index.txt'), tmpfile('serial'))
    end

    def build_ta_key
      `openvpn --genkey --secret #{tmppath('ta.key')}`
      @tracker.set_ta_key(tmpfile('ta.key'))
    end

    def place_file(name)
      if data = @tracker.db.data(name)
        File.open(File.join(@tmpdir, name), 'w') {|f| f.write(data)}
      else
        raise "No data for #{name}"
      end
    end

    def tmppath(f, extn=nil); File.join(@tmpdir, extn ? "#{f}.#{extn}" : f); end
    def tmpfile(*args); File.read(tmppath(*args)); end

    def build_key(user, name, email, pass, delegate)
      h = {:key_cn => name, :key_name => name, :key_email => email}
      place_file('ca.crt')
      place_file('ca.key')
      place_file('index.txt')
      place_file('serial')

      `openssl req -batch -days 3650 -new -keyout #{tmppath(user, 'key')} -out #{tmppath(user, 'csr')} -config #{opensslcnf(h)} -passin pass:#{pass} -passout pass:#{pass}`
      `openssl ca -batch -days 3650 -out #{tmppath(user, 'crt')} -in #{tmppath(user, 'csr')} -config #{opensslcnf(h)}`
      `openssl pkcs12 -export -clcerts -in #{tmppath(user, 'crt')} -inkey #{tmppath(user, 'key')} -out #{tmppath(user, 'p12')} -passin pass:#{pass} -passout pass:#{pass}`
      @tracker.send(delegate, user, name, email, tmpfile(user, 'key'), tmpfile(user, 'crt'), tmpfile(user, 'p12') tmpfile('index.txt'), tmpfile('serial'))
    end

    def revoke_key(user, version)
      h = {:key_cn => ""}
      place_file('ca.crt')
      place_file('ca.key')
      place_file('crl.pem')
      place_file('index.txt')
      place_file('serial')

      user_crt = tmppath(user, 'crt')
      rev_crt = tmppath('rev-test.crt')
      File.open(user_crt, 'w') {|f| f.write(@tracker.key(user, version, 'crt'))}
      `openssl ca -revoke #{user_crt} -keyfile #{tmppath('ca.key')} -cert #{tmppath('ca.crt')} -config #{opensslcnf(h)}`
      gen_crl

      File.open(rev_crt, 'w') {|f| f.write(File.read(tmppath('ca.crt'))); f.write(File.read(tmppath('crl.pem')))}
      if `openssl verify -CAfile #{rev_crt} -crl_check #{user_crt}` =~ /certificate revoked/
        @tracker.user_key_revoked(user, version, tmpfile('crl.pem'), tmpfile('index.txt'))
      else
        raise "Revocation verification failed: openssl isn't recognizing it"
      end
    end
  end
end
