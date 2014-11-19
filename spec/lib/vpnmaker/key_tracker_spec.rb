require 'spec_helper'

describe VPNMaker::KeyTracker do

  after(:each) do
    FileUtils.rm_rf vpn_root
  end
  
  it "should generate the config folders" do
    VPNMaker::KeyTracker.generate("my", vpn_root)
    expect(File.directory? vpn_root(:my)).to be_true
  end
end