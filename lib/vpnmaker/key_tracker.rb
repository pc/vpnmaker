module VPNMaker
  class KeyTracker
    attr_reader :builder
    attr_reader :db
    attr_reader :config
    attr_reader :path

    def initialize(name, dir)
      @path = dir
      @db = KeyDB.new(File.join(dir, name + '.db.yaml'))
      @config = KeyConfig.new(File.join(dir, name + '.config.yaml'))
      @builder = KeyBuilder.new(self, @config)
    end

    def self.generate(name, path=nil)
      path ||= '/tmp'
      dir = File.join(File.expand_path(path), name + '.vpn')

      FileUtils.mkdir_p(dir)
      dbpath = File.join(dir, "#{name}.db.yaml")

      db = KeyDB.new(dbpath)
      db[:version] = 0
      db[:modified] = Time.now
      db[:users] = {}
      db[:datadir] = "data"
      db.sync
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

    def add_key(user, key, crt, p12, ver)
      @db.dump("#{user}-#{ver}.key", key)
      @db.dump("#{user}-#{ver}.crt", crt)
      @db.dump("#{user}-#{ver}.p12", p12)
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
  end

  def self.generate(name, path)
    KeyTracker.generate(name, path)
  end
end
