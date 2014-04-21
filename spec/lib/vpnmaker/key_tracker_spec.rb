require 'spec_helper'

describe VPNMaker::KeyTracker, fakefs: true do
  it "should generate the config folders" do
    VPNMaker::KeyTracker.generate("my", vpn_root)
    expect(File.directory? vpn_root(:my)).to be_true
  end
end