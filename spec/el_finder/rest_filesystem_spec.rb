require 'spec_helper'

describe RestFilesystem do

  def expected_source
    File.expand_path("../config/application.yml", File.dirname(__FILE__))
  end

  before do
    RestSettings.stub(:default_source).and_return(expected_source)
    RestSettings.stub(:default_namespace).and_return("test")
  end

  after do
    if subject.constants.include?(:SERVER_URL)
      subject.send(:remove_const, :SERVER_URL)
    end
  end

  let(:subject) { RestFilesystem }

  describe "::init" do

    let(:filesystem_server) { "http://test-server:8080/service-rest/rest/filesystem" }

    it 'initialize SERVER_URL constant' do
      expect { subject::SERVER_URL }.to raise_error("uninitialized constant RestFilesystem::SERVER_URL")
      subject.init(nil)
      expect(subject::SERVER_URL).to eq(filesystem_server)
    end

  end # ::init


  describe "::get" do

    context "when do not call ::init" do

      it 'raises NameError' do
        expect { subject.get }.to raise_error(NameError, "uninitialized constant RestFilesystem::SERVER_URL")
      end

    end

    it 'calls ::validation' do
      subject.should_receive(:validation).and_return("fake")
      subject.stub(:request)
      
      subject.init(nil)
      subject.get
    end

    it 'calls ::request' do
      subject.should_receive(:request)
      
      subject.init(nil)
      subject.get
    end

  end # ::get


  describe "::validation" do
    it 'raises NoMethodError, because it is a private method' do
      expect { subject.validation }.to raise_error(NoMethodError)
    end
  end # ::validation


  describe "::request" do
    it 'raises NoMethodError, because it is a private method' do
      expect { subject.request }.to raise_error(NoMethodError)
    end
  end # ::request


  describe "::params" do
    it 'raises NoMethodError, because it is a private method' do
      expect { subject.params }.to raise_error(NoMethodError)
    end
  end # ::request


  describe "::parser" do
    it 'raises NoMethodError, because it is a private method' do
      expect { subject.parser }.to raise_error(NoMethodError)
    end

    let(:json) { '{"t":"test"}' }
    let(:expected_hash) { { 't' => 'test' } }
    
    it 'correct parse json' do
      expect( subject.send(:parser, json) ).to eq(expected_hash)
    end

  end # ::request

end