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

  def stub_rest_client(json)
    RestClient.should_receive(:send).and_return(json)
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


  let(:json) { '{"t":"test"}' }
  let(:expected_hash) { { 't' => 'test' } }

  describe "::get" do

    context "when was not invoke ::init" do

      it 'raises NameError' do
        expect { subject.get }.to raise_error(NameError, "uninitialized constant RestFilesystem::SERVER_URL")
      end

    end

    it 'invokes ::validation' do
      stub_rest_client(json)
      subject.should_receive(:validation).and_return("fake")
      
      subject.init(nil)
      expect { subject.get({}) }.to_not raise_error
    end

    it 'invokes ::request' do
      subject.should_receive(:request)
      
      subject.init(nil)
      expect { subject.get({}) }.to_not raise_error
    end

    it 'invokes ::params' do
      stub_rest_client(json)
      subject.should_receive(:params)
      
      subject.init(nil)
      expect { subject.get({}) }.to_not raise_error
    end

    it 'returns hash' do
      stub_rest_client(json)
      subject.init(nil)

      expect( subject.get({}) ).to eq(expected_hash)
    end

  end # ::get


  describe "::validation" do
    it 'raises NoMethodError, because it is a private method' do
      expect { subject.validation }.to raise_error(NoMethodError)
    end

    context "when uninitialized SERVER_URL" do

      it 'raises NameError' do
        expect { subject.send(:validation) }.to raise_error(NameError, "uninitialized constant RestFilesystem::SERVER_URL")
      end

    end
  end # ::validation


  describe "::parser" do
    it 'raises NoMethodError, because it is a private method' do
      expect { subject.parser }.to raise_error(NoMethodError)
    end

    it 'correct parse json' do
      expect( subject.send(:parser, json) ).to eq(expected_hash)
    end

  end # ::parser

  describe "::request" do
    it 'raises NoMethodError, because it is a private method' do
      expect { subject.request }.to raise_error(NoMethodError)
    end

    it 'invokes ::parser' do
      stub_rest_client(json)
      subject.should_receive(:parser)

      subject.send(:request, :get, {})
    end

    it 'returns hash' do
      stub_rest_client(json)

      expect( subject.send(:request, :get, {}) ).to eq(expected_hash)
    end
  end # ::request


  describe "::params" do
    it 'raises NoMethodError, because it is a private method' do
      expect { subject.params }.to raise_error(NoMethodError)
    end

    let(:arguments) { {'key' => "key", 'withChildren' => true }}

    it 'returns hash with arguments in "params" key' do
      expect( subject.send(:params, arguments) ).to eq( { params: arguments } )
    end
  end # ::params

end # RestFilesystem