module VPNMaker
  class Manager
    attr_reader :tracker, :data_dir

    def self.vpn_name(dir); dir =~ /(^|\/)([^\/\.]+)\.vpn/ ? $2 : nil; end

    def initialize(dir)
      name = self.class.vpn_name(File.expand_path(dir))
      @tracker = KeyTracker.new(name, File.expand_path(dir))
      @data_dir = File.join File.expand_path(dir), "data"
    end

    def config; @tracker.config; end

    def build_ca; @tracker.builder.build_ca; end

    def build_server
      @tracker.builder.build_server_key
      @tracker.builder.build_ta_key
      @tracker.builder.build_dh_key
    end

    def create_user(user, name, email, pass=nil)
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

    def regenerate_user(user, pass=nil)
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

    def config_generator(*args); ConfigGenerator.new([self] + args); end
  end
end
