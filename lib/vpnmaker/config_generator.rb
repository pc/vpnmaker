module VPNMaker
  class ConfigGenerator
    def initialize(*args)
      @mgr = args.shift.first
      args.empty? ? (@runtime_cfg = default_template) : (@runtime_cfg = args.shift)
    end

    def default_template
      @dirname = (File.join(@mgr.data_dir))
      {
        :type => :default,
        :dh => File.read(File.join(@dirname, "dh.pem")),
        :ca => File.read(File.join(@dirname, "ca.crt")),
        :ta => File.read(File.join(@dirname, "ta.key"))
      }
    end

    def client_conf(client)
      fname = client[:user] + '-' + ((client[:revoked].max || - 1) + 1).to_s
      separator = '-----BEGIN CERTIFICATE-----'
      cert = File.read(File.join(@dirname, "#{fname}.crt")).split(separator).last.insert(0, separator)

      {
        :gen_host => Socket.gethostname,
        :server => @mgr.config[:server],
        :client => @mgr.config[:client]
      }.merge(client).merge(:key => File.read(File.join(@dirname, "#{fname}.key")),
                            :cert => cert).merge(@runtime_cfg)
    end

    def server_conf
      separator = '-----BEGIN CERTIFICATE-----'
      cert = File.read(File.join(@dirname, "server.crt")).split(separator).last.insert(0, separator)
      {
        :gen_host => Socket.gethostname,
        :crl_path => @mgr.tracker.path
      }.merge(@mgr.config[:server]).merge(@runtime_cfg).merge(
        :key => File.read(File.join(@dirname, "server.key")),
        :cert => cert,
        :crl => File.read(File.join(@dirname, "crl.pem"))
      )
    end

    def server
      haml_vars = server_conf.dup
      haml_vars[:base_ip] = ((a = IPAddr.new haml_vars[:base_ip]); {:net => a.to_s, :mask => a.subnet_mask.to_s})
      haml_vars[:bridgednets] ? (haml_vars[:bridgednets] = haml_vars[:bridgednets].map {|net| a = (IPAddr.new net); {:net => a.to_s, :mask => a.subnet_mask.to_s}}) : (haml_vars[:bridgednets] = Hash.new)
      haml_vars[:subnets] ? (haml_vars[:subnets] = haml_vars[:subnets].map {|net| a = (IPAddr.new net); {:net => a.to_s, :mask => a.subnet_mask.to_s}}) : (haml_vars[:subnets] = Hash.new)
      
      template = File.read(VPNMaker.template_path 'server.haml')
      Haml::Engine.new(template).render(Object.new, haml_vars)
    end

    def client(client)
      haml_vars = client_conf(client).dup
      
      template = File.read(VPNMaker.template_path 'client.haml')
      Haml::Engine.new(template).render(Object.new, haml_vars)
    end
  end
end
