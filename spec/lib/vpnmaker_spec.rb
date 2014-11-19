require 'spec_helper'

describe VPNMaker do

  after(:each) do
    FileUtils.rm_rf vpn_root
  end
  
  it "should generate a vpn" do
    VPNMaker.generate("my", vpn_root)
    expect(File.exist? vpn_root(:my)).to be_true
  end

end