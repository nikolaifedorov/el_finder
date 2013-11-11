require 'spec_helper'

describe ElFinder::Connector::RestConnector do

  let(:options) do
    {
      :driver => 'rest',
      :root => '/',
      :url => 'elfinder_url',
      :rest_file => 'test_rest_file.yml',
     }
  end

  let(:file) {
    { 
      'key' => "69ca003d-a482-49fc-8466-9896d5fa03e6",
      'name' => "example2.gff",
      'format' => "gff",
      'size' => 0,
      'nodeType' => "FILE",
      'fullPath' => "/example2.gff",
      'children' => nil,
      'attributes' => nil
    }
  }

  let(:folder) {
    {
      'key' => "d061f348-64a5-47cf-bad3-e273dd4e06a6",
      'name' => "root",
      'format' => nil,
      'size' => 0,
      'nodeType' => "FOLDER",
      'fullPath' => "/",
      'children' => [ file ],
      'attributes' => []
    }
  }

  let(:fake_rest_service) do
    service = double(RestFilesystem)
    service.stub(:get) { folder }

    RestFilesystem.stub(:init).and_return(service)
    service
  end


  before do
    fake_rest_service
  end


  let(:connector) { ElFinder::Connector::RestConnector }


  describe 'initialize' do
    it { expect { connector.new(options) }.not_to raise_error }

    it { expect { connector.new({}) }.to raise_error(ArgumentError, "Missing required :root option") }
    it { expect { connector.new({ :root => "" }) }.to raise_error(ArgumentError, "Missing required :rest_file option") }
    it { expect { connector.new({ :root => "", :rest_file => "" }) }.not_to raise_error }
  end


  let(:rest_connector) { connector.new(options) }

  let(:pathname) { ElFinder::ConnectionPathnames::RestPathname.new(fake_rest_service, options[:root], "/files/test")}
  let(:expected_hash) { "rest_L2ZpbGVzL3Rlc3Q" }

  describe '#to_hash' do
    it { expect(rest_connector.to_hash(pathname)).to eql(expected_hash) }
  end


  let(:expected_path) { "/test/test" }
  let(:validate_hash) { "rest_L3Rlc3QvdGVzdA" }

  describe "#from_hash" do
    it { expect(rest_connector.from_hash(validate_hash).path.to_s).to eql(expected_path) }
  end


  context "#tree" do
    let(:expected_tree) do 
      {
        :name=>"REST-Home", 
        :hash=>"rest_Lg", 
        :dirs=> [], 
        :volumeid=>"rest", 
        :read=>true, 
        :write=>true, 
        :rm=>true, 
        :hidden=>false
      }
    end

    it { expect(rest_connector.tree).to eql(expected_tree) }
  end


  context "#run" do

    let(:expected_response) do
      {
        :cdc => [
          {
            :name=>"example2.gff", 
            :hash=>"rest_ZXhhbXBsZTIuZ2Zm", 
            :date=>0, 
            :read=>true, 
            :write=>true, 
            :rm=>true, 
            :hidden=>false, 
            :size=>0, 
            :mime=>"unknown/unknown", 
            :url=>"elfinder_url/example2.gff"
          }
        ],
        :cwd => {
          :name=>".",
          :hash=>"rest_Lg",
          :mime=>"directory",
          :rel=>"REST-Home",
          :size=>0,
          :date=>0,
          :read=>true,
          :write=>true,
          :rm=>true,
          :hidden=>false
        },
        :disabled => [],
        :netDrivers => [:ftp],
        :params => {:dotFiles=>true, :uplMaxSize=>"50M", :archives=>[], :extract=>[], :url=>"elfinder_url"}
      }
    end

    context "cmd 'open'" do
      it { expect(rest_connector.run({:cmd => 'open', :init => 'true', :target => ''})[1]).to eql( expected_response ) }
    end


    context "cmd 'mkdir'" do
      it { expect(rest_connector.run({:cmd => 'mkdir'})[1][:error]).to eql( "Invalid command 'mkdir'" ) }
    end

  end # context "#run"

end # ElFinder::Connector::RestConnector