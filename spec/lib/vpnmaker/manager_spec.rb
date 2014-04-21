require 'spec_helper'
require 'fileutils'

describe VPNMaker::Manager do
  subject(:manager) { VPNMaker::Manager.new( vpn_root(:my) ) }

  before(:each) do
    FileUtils.mkdir_p "/tmp/keybuilder"
  end

  after(:each) do
    FileUtils.rm_rf vpn_root
  end

  context "when there is no config file" do
    it "should raise an error" do
      expect { VPNMaker::Manager.new vpn_root(:my) }.to raise_error
    end
  end

  context "when there is a config file" do
    before(:each) do
      VPNMaker.generate "my", vpn_root
      File.open("#{vpn_root(:my)}/my.config.yaml", "w") { |f| f.write key_props.to_yaml }
    end

    it "should create an instance of manager" do
      expect( manager ).to be_an_instance_of VPNMaker::Manager
    end

    it "should build the intial keys and files" do
      manager.build_ca
      expect(File.exist? "#{vpn_data(:my)}/ca.crt").to be_true
      expect(File.exist? "#{vpn_data(:my)}/ca.key").to be_true
      expect(File.exist? "#{vpn_data(:my)}/crl.pem").to be_true
      expect(File.exist? "#{vpn_data(:my)}/index.txt").to be_true
      expect(File.exist? "#{vpn_data(:my)}/serial").to be_true
    end

    it "should build the server keys" do
      manager.build_ca
      manager.build_server
      expect(File.exist? "#{vpn_data(:my)}/server.crt").to be_true
      expect(File.exist? "#{vpn_data(:my)}/server.key").to be_true
      expect(File.exist? "#{vpn_data(:my)}/dh.pem").to be_true
      expect(File.exist? "#{vpn_data(:my)}/ta.key").to be_true
    end

    it "should create a new user" do
      manager.build_ca
      manager.build_server
      manager.create_user 'joe', 'Joe Bloggs', 'joe.bloggs@example.com', 'password'
      expect(manager.users).to include "joe"
    end

    context "and a user has been created" do
      before(:each) do
        manager.build_ca
        manager.build_server
        manager.create_user 'joe', 'Joe Bloggs', 'joe.bloggs@example.com', 'password'
      end

      it "should have user details" do
        details = manager.user('joe')
        expect(details).to be_a Hash
        expect(details[:email]).to eq 'joe.bloggs@example.com'
      end

      it "should have no revoked keys" do
        details = manager.user('joe')
        expect(details[:revoked]).to be_empty
        expect(details[:active_key]).to eq 0
      end

      context "and a user has had a key revoked" do
        it "should have a revoked key in the user details" do
          manager.regenerate_user('joe', 'newpassword')
          details = manager.user('joe')
          expect(details[:revoked]).to eq [0]
          expect(details[:active_key]).to eq 1
        end
      end
    end

    context "when there are no server configs" do
      it "should raise an error" do
        expect {
          manager.config_generator.server
        }.to raise_error
      end
    end

    context "when there are server configs" do
      before(:each) do
        c = YAML.load_file("#{vpn_root(:my)}/my.config.yaml")
        c.merge! server_props
        File.open("#{vpn_root(:my)}/my.config.yaml", "w") { |f| f.write c.to_yaml }
      end

      it "should build the server config" do
        manager.build_ca
        manager.build_server
        config = manager.config_generator.server
        expect(config).to include "10.10.10.0"
        expect(config).to include "example.com"
        expect(config).to include "1194"
      end
    end

  end

end