require 'spec_helper'

describe ElFinder::Connector::EjbAndOtherStorage do

  def vroot 
    File.expand_path("../../../tmp/elfinder", File.dirname(__FILE__))
  end

  let(:options) do
    {
      :driver => 'ejb_and',
      :driver_other => 'local',
      :root => vroot,
      :url => 'elfinder_url',
      :jndi_file => 'test_jndi_file.yml',
      :ejb_service => 'test_ejb_service',
     }
  end


  let(:null_object) { double('null object').as_null_object }


  let(:folder_null_object) do
    folder = double('null object').as_null_object
    folder.stub(:getName) { "Folder1" }

    folder
  end


  let(:file_null_object) do
    file = double('null object').as_null_object
    file.stub(:getName) { "File1" }

    file
  end


  let(:fake_ejb_service) do
    ejb_service = double('JavaEjbServiceFake')
    ejb_service.stub(:findFolder) { null_object }
    
    ejb_service.stub(:getFolders) { [] }
    ejb_service.stub(:getFolders).with(null_object) { [ folder_null_object ] }

    ejb_service.stub(:getFiles) { [] }
    ejb_service.stub(:getFiles).with(null_object) { [ file_null_object ] }

    ejb_service
  end


  let(:fake_ejb_context) do
    ejb_context = double('JavaEjbContexFake')
    ejb_context.stub(:get_service) { fake_ejb_service }

    ejb_context
  end


  def stub_ejb_context
    ElFinder::Rejb.stub(:context) { fake_ejb_context }
  end


  before do
    FileUtils.mkdir_p(vroot)
    FileUtils.cp_r File.expand_path("../../../test/files/", File.dirname(__FILE__)), vroot

    stub_ejb_context
  end

  after do
    FileUtils.rm_rf(vroot)
    FileUtils.rm_rf("tmp")
  end


  context "initialize" do
    it { expect { ElFinder::Connector::EjbAndOtherStorage.new(options) }.not_to raise_error }

    it { expect { ElFinder::Connector::EjbAndOtherStorage.new({}) }.to raise_error(ArgumentError, "Missing required :driver_other option") }
  end


  let(:connector) { ElFinder::Connector::EjbAndOtherStorage.new(options) }

  context "#tree" do
    let(:expected_tree) do 
      {
        :name=>"EJB-and-Other-Home", 
        :hash=>"EaO_Lg", 
        :dirs=> [
          {
            :name=>"Folder1", 
            :hash=>"EaO_Rm9sZGVyMQ", 
            :dirs=>[], 
            :read=>true, 
            :write=>true, 
            :rm=>true, 
            :hidden=>false
          }
        ], 
        :volumeid=>"EaO", 
        :read=>true, 
        :write=>true, 
        :rm=>true, 
        :hidden=>false
      }
    end

    it { expect(connector.tree).to eql(expected_tree) }
  end


  context "#run" do

    context "cmd 'open'" do

      let(:expected_response) do
        {
          :cdc => [
            {
              :name=>"File1", 
              :hash=>"EaO_RmlsZTE", 
              :date=>0, 
              :read=>true, 
              :write=>true, 
              :rm=>true, 
              :hidden=>false, 
              :size=>0, 
              :mime=>"unknown/unknown", 
              :url=>"elfinder_url/File1"
            }, 
            {
              :name=>"Folder1",
              :hash=>"EaO_Rm9sZGVyMQ",
              :date=>0,
              :read=>true,
              :write=>true,
              :rm=>true,
              :hidden=>false,
              :size=>0,
              :mime=>"directory"
            }
          ],
          :cwd => {
            :name=>".",
            :hash=>"EaO_Lg",
            :mime=>"directory",
            :rel=> "EJB-and-Other-Home",
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

      it { expect(connector.run({:cmd => 'open', :init => 'true', :target => ''})[1]).to eql( expected_response ) }
    end # context "cmd 'open'"


    context "cmd 'mkdir'" do

      let(:expected_response) do
        {
          :select=>["l_ZGlyMQ"],
          :cwd=>{
            :name=>".",
            :hash=>"l_Lg",
            :mime=>"directory",
            :rel=>"EJB-and-Other-Home",
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
            :name=>"EJB-and-Other-Home",
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
        response = connector.run(cmd_mkdir)[1]
        response[:cwd][:date] = ""
        response[:cdc].each { |item| item[:date] = "" }

        expect(response).to eql( expected_response )
      end
    end # context "cmd 'mkdir'"

  end # context "#run"

end