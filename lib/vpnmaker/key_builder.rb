module VPNMaker
  class KeyBuilder
    def initialize(tracker, config)
      @tmpdir = File.join tracker.path, "tmp"
      clean_tmpdir
      @tracker = tracker
      @config = config
    end

    def clean_tmpdir
      FileUtils.rm_rf(@tmpdir)
      FileUtils.mkdir_p(@tmpdir)
    end

    def cnfpath; File.join @tmpdir, "openssl-#{$$}.cnf"; end

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
        :key_ou => @config[:key_properties][:organization_unit],
        :key_cn => @config[:key_properties][:common_name],
        :key_name => @config[:key_properties][:name]
      }
    end

    def init
      `touch #{@dir}/index.txt`
      `echo 01 > #{@dir}/serial`
    end

    def opensslcnf(hash={})
      c = cnfpath

      template = File.read(VPNMaker.template_path('openssl.haml'))
      haml = Haml::Engine.new(template)
      config = haml.render(Object.new, opensslvars.merge(hash))

      File.open(cnfpath, 'w') do |f|
        f.write(config)
      end

      c
    end

    # Build Diffie-Hellman parameters for the server side of an SSL/TLS connection.
    def build_dh_key(keysize=1024)
      `openssl dhparam -out #{tmppath('dh.pem')} #{keysize}`

      raise BuildError, "DH key was empty" if tmpfile('dh.pem').empty?

      @tracker.set_dh(tmpfile('dh.pem'))
    end

    def ca
      @tracker[:ca]
    end

    def gen_crl
      `openssl ca -gencrl -crldays 3650 -keyfile #{tmppath('ca.key')} -cert #{tmppath('ca.crt')} -out #{tmppath('crl.pem')} -config #{opensslcnf}`
      
      raise BuildError, "CRL was empty" if tmpfile('crl.pem').empty?
    end

    def build_ca
      index = tmppath('index.txt')

      FileUtils.touch(index)

      `openssl req -batch -days 3650 -nodes -new -x509 -keyout #{@tmpdir}/ca.key -out #{@tmpdir}/ca.crt -config #{opensslcnf}`

      gen_crl

      raise BuildError, "CA certificate was empty" if tmpfile('ca.crt').empty?
      raise BuildError, "CA key was empty" if tmpfile('ca.key').empty?

      @tracker.set_ca(tmpfile('ca.key'), tmpfile('ca.crt'), tmpfile('crl.pem'), tmpfile('index.txt'), "01\n")
    end

    def build_server_key
      place_file('ca.crt')
      place_file('ca.key')
      place_file('index.txt')
      place_file('serial')

      `openssl req -batch -days 3650 -nodes -new -keyout #{tmppath('server.key')} -out #{tmppath('server.csr')} -extensions server -config #{opensslcnf}`
      `openssl req -batch -days 3650 -out #{tmppath('server.crt')} -in #{tmppath('server.csr')} -extensions server -config #{opensslcnf}`

      raise BuildError, "Server certificate was empty" if tmpfile('server.crt').empty?
      raise BuildError, "Server key was empty" if tmpfile('server.key').empty?

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
      h = {:key_cn => user, :key_name => name, :key_email => email}
      place_file('ca.crt')
      place_file('ca.key')
      place_file('index.txt')
      place_file('serial')
      if pass
        pass_spec = "-passin 'pass:#{pass}' -passout 'pass:#{pass}'"
      else
        pass_spec = '-nodes'
      end
      `openssl req -batch -days 3650 -new -keyout #{tmppath(user, 'key')} -out #{tmppath(user, 'csr')} -config #{opensslcnf(h)} -nodes`
      `openssl ca -batch -days 3650 -out #{tmppath(user, 'crt')} -in #{tmppath(user, 'csr')} -config #{opensslcnf(h)}`
      # TODO: this still asks for the export password and we hack
      # around it from bin/vpnmaker. This is actually something that
      # should only be generated dynamically upon user request.
      `openssl pkcs12 -export -clcerts -in #{tmppath(user, 'crt')} -inkey #{tmppath(user, 'key')} -out #{tmppath(user, 'p12')} #{pass_spec}`
      @tracker.send(delegate, user, name, email, tmpfile(user, 'key'), tmpfile(user, 'crt'), tmpfile(user, 'p12'), tmpfile('index.txt'), tmpfile('serial'))
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
