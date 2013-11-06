require 'spec_helper'

describe RestSettings do

  describe "::init" do

    def expected_source
      File.expand_path("../config/application.yml", File.dirname(__FILE__))
    end

    let(:filesystem_server) { "http://test-server:8080/service-rest/rest/filesystem" }

    it 'init correct configuration' do
      RestSettings.should_receive(:default_source).and_return(expected_source)
      RestSettings.should_receive(:default_namespace).and_return("test")

      RestSettings.init

      expect(RestSettings.filesystem_server).to eq(filesystem_server)
    end

  end

end