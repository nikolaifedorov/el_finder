require 'spec_helper'

describe ElFinder::Connector::LocalFileSystem do

  def vroot 
    File.expand_path("../../../tmp/elfinder", File.dirname(__FILE__))
  end

  let(:options) do
    {
      :driver => 'local',
      :root => vroot,
      :url => 'elfinder_url'
    }
  end


  before do
    FileUtils.mkdir_p(vroot)
    FileUtils.cp_r File.expand_path("../../../test/files/", File.dirname(__FILE__)), vroot
  end

  after do
    FileUtils.rm_rf(vroot)
    FileUtils.rm_rf("tmp")
  end


  context "initialize" do
    it { expect { ElFinder::Connector::LocalFileSystem.new(options) }.not_to raise_error }

    it { expect { ElFinder::Connector::LocalFileSystem.new({}) }.to raise_error(ArgumentError, "Missing required :url option") }
    it { expect { ElFinder::Connector::LocalFileSystem.new({ :url => "" }) }.to raise_error(ArgumentError, "Missing required :root option") }
    it { expect { ElFinder::Connector::LocalFileSystem.new({ :url => "", :root => "" }) }.not_to raise_error }
  end


  let(:connector) { ElFinder::Connector::LocalFileSystem.new(options) }
  let(:pathname) { ElFinder::ConnectionPathnames::FileSystemPathname.new(nil, options[:root])}
  
  let(:expected_hash_root) { "l_Lg" }
  let(:validate_hash) { "local_Lg" }


  context "#to_hash" do
    it { expect(connector.to_hash(pathname)).to eql(expected_hash_root) }
  end


  context "#from_hash" do
    it { expect(connector.from_hash(validate_hash).path).to eq(pathname.path) }
  end


  context "#tree" do
    let(:expected_tree) do 
      {
        :name=>"Home", 
        :hash=>"l_Lg", 
        :dirs=> [ 
                  {
                    :name=>"files",
                    :hash=>"l_ZmlsZXM",
                    :dirs=> [
                              {
                                :name=>"foo",
                                :hash=>"l_ZmlsZXMvZm9v",
                                :dirs=>[],
                                :read=>true,
                                :write=>true,
                                :rm=>true,
                                :hidden=>false
                              }
                    ], 
                    :read=>true,
                    :write=>true,
                    :rm=>true,
                    :hidden=>false
                  }
        ], 
        :volumeid=>"l", 
        :read=>true, 
        :write=>true, 
        :rm=>false, 
        :hidden=>false
      }
    end

    it { expect(connector.tree).to eql(expected_tree) }
  end


  context "#run" do

    context "cmd 'open'" do

      let(:expected_response) do
        {
          :cwd => {
            :name=>".",
            :hash=>"l_Lg",
            :mime=>"directory",
            :rel=>"Home",
            :size=>0,
            :date => "",
            # :date=>"2013-10-11 16:36:32 +0400",
            :read=>true,
            :write=>true,
            :rm=>false,
            :hidden=>false
          },
          :cdc => [
                    {
                      :name=>"files",
                      :hash=>"l_ZmlsZXM",
                      :date => "",
                      # :date=>"2013-10-11 16:36:32 +0400",
                      :read=>true,
                      :write=>true,
                      :rm=>true,
                      :hidden=>false,
                      :size=>0,
                      :mime=>"directory"
                    }
          ],        
          :disabled => [],
          :params => {
            :dotFiles=>true,
            :uplMaxSize=>"50M",
            :archives=>[],
            :extract=>[],
            :url=>"elfinder_url"
          }
        }
      end

      it do
        response = connector.run({:cmd => 'open', :init => 'true', :target => ''})[1]
        response[:cwd][:date] = ""
        response[:cdc][0][:date] = ""

        expect(response).to eql( expected_response )
      end
    end


    context "cmd 'mkdir'" do

      let(:expected_response) do
        {
          :select=>["l_ZGlyMQ"],
          :cwd=> {
            :name=>".",
            :hash=>"l_Lg",
            :mime=>"directory",
            :rel=>"Home",
            :size=>0,
            :date=>"",
            # :date=>"2013-10-11 17:06:04 +0400",
            :read=>true,
            :write=>true,
            :rm=>false,
            :hidden=>false
          },
          :cdc=> [
            {
              :name=>"dir1",
              :hash=>"l_ZGlyMQ",
              :date=>"",
              # :date=>"2013-10-11 17:06:04 +0400",
              :read=>true,
              :write=>true,
              :rm=>true,
              :hidden=>false,
              :size=>0,
              :mime=>"directory"
            },
            {
              :name=>"files",
              :hash=>"l_ZmlsZXM",
              :date=>"",
              # :date=>"2013-10-11 17:06:04 +0400",
              :read=>true,
              :write=>true,
              :rm=>true,
              :hidden=>false,
              :size=>0,
              :mime=>"directory"
            }
          ],
          :tree=> {
            :name=>"Home",
            :hash=>"l_Lg",
            :dirs=> [
              {
                :name=>"dir1",
                :hash=>"l_ZGlyMQ",
                :dirs=>[],
                :read=>true,
                :write=>true,
                :rm=>true,
                :hidden=>false
              },
              {
                :name=>"files",
                :hash=>"l_ZmlsZXM",
                :dirs=> [
                  {
                    :name=>"foo",
                    :hash=>"l_ZmlsZXMvZm9v",
                    :dirs=>[],
                    :read=>true,
                    :write=>true,
                    :rm=>true,
                    :hidden=>false
                  }
                ],
                :read=>true,
                :write=>true,
                :rm=>true,
                :hidden=>false
              }
            ],
            :volumeid=>"l",
            :read=>true,
            :write=>true,
            :rm=>false,
            :hidden=>false
          }
        }
      end

      let(:cmd_mkdir) { { :cmd => 'mkdir', :current => "l_Lg", :name => 'dir1'} }

      it do
        response = connector.run(cmd_mkdir)[1]
        response[:cwd][:date] = ""
        response[:cdc].each { |item| item[:date] = "" }

        expect(response).to eql( expected_response )
      end

    end

  end # context "#run"

end