require 'spec_helper'

describe ElFinder::Connector::EjbAndOtherStorage do

  def vroot 
    File.expand_path("../../../tmp/elfinder", File.dirname(__FILE__))
  end

  let(:options) do
    {
      :driver => 'rest_and',
      :driver_other => 'local',
      :root => "/",
      :root_other => vroot,
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
    FileUtils.mkdir_p(vroot)
    FileUtils.cp_r File.expand_path("../../../test/files/", File.dirname(__FILE__)), vroot

    fake_rest_service
  end


  after do
    FileUtils.rm_rf(vroot)
    FileUtils.rm_rf("tmp")
  end

  let(:connector) { ElFinder::Connector::RestAndOtherStorage }

  describe "initialize" do
    it { expect { connector.new(options) }.not_to raise_error }

    it { expect { connector.new({}) }.to raise_error(ArgumentError, "Missing required :driver_other option") }
    it { expect { connector.new({:driver_other => ""}) }.to raise_error(ArgumentError, "Missing required :root_other option") }
  end


  let(:rest_and_other_connector) { connector.new(options) }

  describe '#tree' do
    let(:expected_tree) do 
      {
        :name=>"REST-and-Other-Home", 
        :hash=>"RaO_Lg", 
        :dirs=> [], 
        :volumeid=>"RaO", 
        :read=>true, 
        :write=>true, 
        :rm=>true, 
        :hidden=>false
      }
    end

    it { expect(rest_and_other_connector.tree).to eql(expected_tree) }
  end


  describe "#run" do

    context "cmd 'open'" do

      let(:expected_response) do
        {
          :cdc => [
            {
              :name=>"example2.gff", 
              :hash=>"RaO_ZXhhbXBsZTIuZ2Zm", 
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
            :hash=>"RaO_Lg",
            :mime=>"directory",
            :rel=>"REST-and-Other-Home",
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

      let(:open_cmd_params) { {:cmd => 'open', :init => 'true', :target => ''} }

      it { expect(rest_and_other_connector.run( open_cmd_params )[1]).to eql( expected_response ) }
    end # cmd 'open'


    context "cmd 'mkdir'" do

      let(:expected_response) do
        {
          :select=>["l_ZGlyMQ"],
          :cwd=>{
            :name=>".",
            :hash=>"l_Lg",
            :mime=>"directory",
            :rel=>"REST-and-Other-Home",
            :size=>0,
            :date => "",
            # :date=>"2013-10-11 18:19:39 +0400",
            :read=>true,
            :write=>true,
            :rm=>false,
            :hidden=>false
          },
          :cdc=>[
            {
              :name=>"dir1",
              :hash=>"l_ZGlyMQ",
              :date=>"",
              # :date=>"2013-10-11 18:19:39 +0400",
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
              :date => "",
              # :date=>"2013-10-11 18:19:39 +0400",
              :read=>true,
              :write=>true,
              :rm=>true,
              :hidden=>false,
              :size=>0,
              :mime=>"directory"
            }
          ],
          :tree=>{
            :name=>"REST-and-Other-Home",
            :hash=>"l_Lg",
            :dirs=>[
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
                :dirs=>[
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

      let(:cmd_mkdir) { { :cmd => 'mkdir', :current => "EaO_Lg", :name => 'dir1'} }

      it do
        response = rest_and_other_connector.run(cmd_mkdir)[1]
        response[:cwd][:date] = ""
        response[:cdc].each { |item| item[:date] = "" }

        expect(response).to eql( expected_response )
      end
    end # cmd 'mkdir'

  end # #run

end