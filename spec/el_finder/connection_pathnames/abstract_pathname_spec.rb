require 'spec_helper'


describe ElFinder::ConnectionPathnames::AbstractPathname do
  
  let(:klass) { ElFinder::ConnectionPathnames::AbstractPathname }
  let(:root_pathname) { klass.new(nil, "/") }
  let(:not_root_pathname) { klass.new(nil, "/test/test/") }


  context "when initialize and entry_metadata is nil" do

    it "calls #get_entry_metadata" do
      klass.any_instance.should_receive(:get_entry_metadata)
      klass.new(nil, "/")
    end

  end


  context "#is_root?" do

    it "returns true if it is root" do
      root_pathname.is_root?.should be_true
    end

    it "returns false if it is not root" do
      not_root_pathname.is_root?.should be_true
    end

  end # context "#is_root?"


end