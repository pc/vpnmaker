require 'spec_helper'
require 'fileutils'

describe VPNMaker::Manager do
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
      expect( VPNMaker::Manager.new vpn_root(:my) ).to be_an_instance_of VPNMaker::Manager
    end

    it "should build the intial keys and files" do
      VPNMaker::Manager.new( vpn_root(:my) ).build_ca
      expect(File.exist? "#{vpn_data(:my)}/ca.crt").to be_true
      expect(File.exist? "#{vpn_data(:my)}/ca.key").to be_true
      expect(File.exist? "#{vpn_data(:my)}/crl.pem").to be_true
      expect(File.exist? "#{vpn_data(:my)}/index.txt").to be_true
      expect(File.exist? "#{vpn_data(:my)}/serial").to be_true
    end

  end

end