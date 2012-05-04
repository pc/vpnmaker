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

    def apply_erb(name, cnf)
      erb = File.read(__FILE__.path(name))
      ERB.new(erb).result(HashBinding.from_hash(cnf).binding)
    end

    def server; apply_erb('server.erb', server_conf); end

    def client(client)
      apply_erb('client.erb', client_conf(client));
    end
  end
end
