module VPNMaker
  class ConfigGenerator
    def initialize(mgr)
      @mgr = mgr
    end

    def client_conf(client)
      {
        :gen_host => Socket.gethostname,
        :server => @mgr.config[:server],
        :client => @mgr.config[:client]
      }.merge(client)
    end

    def server_conf
      {
        :gen_host => Socket.gethostname
      }.merge(@mgr.config[:server])
    end

    def server
      haml_vars = server_conf.dup
      haml_vars[:base_ip] = ((a = IPAddr.new haml_vars[:base_ip]); {:net => a.to_s, :mask => a.subnet_mask.to_s})
      haml_vars[:bridgednets] = haml_vars[:bridgednets].map {|net| a = (IPAddr.new net); {:net => a.to_s, :mask => a.subnet_mask.to_s}}
      haml_vars[:subnets] = haml_vars[:subnets].map {|net| a = (IPAddr.new net); {:net => a.to_s, :mask => a.subnet_mask.to_s}}
      template = File.read(__FILE__.path('server.haml'))
      Haml::Engine.new(template).render(Object.new, haml_vars)
    end

    def client(client)
      haml_vars = client_conf(client).dup
      template = File.read(__FILE__.path('client.haml'))
      Haml::Engine.new(template).render(Object.new, haml_vars)
    end
  end
end
