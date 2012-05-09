module VPNMaker
  class ConfigGenerator
    def initialize(*args)
      @mgr = args.shift.first
      args.empty? ? (@runtime_cfg = default_template) : (@runtime_cfg = args.shift)
    end

    def default_template
      @dirname = (@mgr.tracker.path + "/" + @mgr.config[:site][:data_dir])
      {
        :type => :default,
        :dh => File.read(@dirname + "/dh.pem"),
        :ca => File.read(@dirname + "/ca.crt"),
        :ta => File.read(@dirname + "/ta.key")
      }
    end
    def client_conf(client)
      {
        :gen_host => Socket.gethostname,
        :server => @mgr.config[:server],
        :client => @mgr.config[:client]
      }.merge(client).merge(:key => File.read(@dirname + "/#{client[:user]}-#{(client[:revoked].max || - 1) + 1}.key" ),
                            :cert => File.read(@dirname + "/#{client[:user]}-#{(client[:revoked].max || - 1) + 1}.crt")).merge(@runtime_cfg)
    end

    def server_conf
      {
        :gen_host => Socket.gethostname
      }.merge(@mgr.config[:server]).merge(@runtime_cfg).merge(:key => File.read(@dirname + "/server.key"),
                                                              :cert => File.read(@dirname + "/server.crt"),
                                                              :crl => File.read(@dirname + "/crl.pem"))
    end

    def server
      haml_vars = server_conf.dup
      haml_vars[:base_ip] = ((a = IPAddr.new haml_vars[:base_ip]); {:net => a.to_s, :mask => a.subnet_mask.to_s})
      haml_vars[:bridgednets] = haml_vars[:bridgednets].map {|net| a = (IPAddr.new net); {:net => a.to_s, :mask => a.subnet_mask.to_s}}
      haml_vars[:subnets] = haml_vars[:subnets].map {|net| a = (IPAddr.new net); {:net => a.to_s, :mask => a.subnet_mask.to_s}}
      template = File.read(@mgr.tracker.path + \
                           "/" + @mgr.config[:site][:template_dir] + \
                           "/" + 'server.haml')
      Haml::Engine.new(template).render(Object.new, haml_vars)
    end

    def client(client)
      haml_vars = client_conf(client).dup
      template = File.read(@mgr.tracker.path + \
                           "/" + @mgr.config[:site][:template_dir] + \
                           "/" + 'client.haml')
      # template = File.read(__FILE__.path('client.haml'))
      Haml::Engine.new(template).render(Object.new, haml_vars)
    end
  end
end
