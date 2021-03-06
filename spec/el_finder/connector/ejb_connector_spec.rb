require 'spec_helper'

describe ElFinder::Connector::EjbConnector do

  let(:options) do
    {
      :driver => 'ejb',
      :root => 'system/elfinder',
      :url => 'elfinder_url',
      :jndi_file => 'test_jndi_file.yml',
      :ejb_service => 'test_ejb_service'
     }
  end


  let(:null_object) { double('null object').as_null_object }

  let(:folder_null_object) do
    folder = double('null filder object').as_null_object
    folder.stub(:getName) { "Folder1" }

    folder
  end


  let(:file_null_object) do
    file = double('null file object').as_null_object
    file.stub(:getFileName) { "File1" }

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
    stub_ejb_context
  end


  let(:connector) { ElFinder::Connector::EjbConnector }

  describe "initialize" do
    it { expect { connector.new(options) }.not_to raise_error }

    it { expect { connector.new({}) }.to raise_error(ArgumentError, "Missing required :root option") }
    it { expect { connector.new({ :root => "" }) }.to raise_error(ArgumentError, "Missing required :jndi_file option") }
    it { expect { connector.new({ :root => "", :jndi_file => "" }) }
                .to raise_error(ArgumentError, "Missing required :ejb_service option")
       }
    it { expect { connector.new({ :root => "", :jndi_file => "", :ejb_service => "" }) }.not_to raise_error }
  end


  let(:ejb_connector) { connector.new(options) }
  let(:pathname) { ElFinder::ConnectionPathnames::EjbPathname.new(fake_ejb_service, options[:root], "/files/test")}
  let(:expected_hash) { "ejb_L2ZpbGVzL3Rlc3Q" }

  context "#to_hash" do
    it { expect(ejb_connector.to_hash(pathname)).to eql(expected_hash) }
  end


  let(:expected_path) { "/test/test" }
  let(:validate_hash) { "ejb_L3Rlc3QvdGVzdA" }

  describe '#from_hash' do
    it { expect(ejb_connector.from_hash(validate_hash).path.to_s).to eql(expected_path) }
  end


  describe '#tree' do
    let(:expected_tree) do 
      {
        :name=>"EJB-Home", 
        :hash=>"ejb_Lg", 
        :dirs=> [
          {
            :name=>"Folder1", 
            :hash=>"ejb_Rm9sZGVyMQ", 
            :dirs=>[], 
            :read=>true, 
            :write=>true, 
            :rm=>true, 
            :hidden=>false
          }
        ], 
        :volumeid=>"ejb", 
        :read=>true, 
        :write=>true, 
        :rm=>true, 
        :hidden=>false
      }
    end

    it { expect(ejb_connector.tree).to eql(expected_tree) }
  end


  describe '#run' do

    let(:expected_response) do
      {
        :cdc => [
          {
            :name=>"File1", 
            :hash=>"ejb_RmlsZTE", 
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
            :hash=>"ejb_Rm9sZGVyMQ",
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
          :hash=>"ejb_Lg",
          :mime=>"directory",
          :rel=>"EJB-Home",
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
      it { expect(ejb_connector.run({:cmd => 'open', :init => 'true', :target => ''})[1]).to eql( expected_response ) }
    end


    context "cmd 'mkdir'" do
      it { expect(ejb_connector.run({:cmd => 'mkdir'})[1][:error]).to eql( "Invalid command 'mkdir'" ) }
    end

  end # #run

end