require 'spec_helper'


describe ElFinder::ConnectionPathnames::FTPPathname do
  
  let(:klass) { ElFinder::ConnectionPathnames::FTPPathname }

  let(:ftp_client_children) do
    ftp_api = double('Net::FTP')
    ftp_api.stub(:pwd)
    ftp_api.stub(:chdir)
    ftp_api.stub(:ls) { ["drwxr-xr-x 4 user     group    4096 Jan  1 00:00 etc", "drwxr-xr-x 4 user     group    4096 Jan  1 00:00 etc2"] }

    ftp_api
  end

  let(:pathname) { klass.new(ftp_client_children, "/") }


  context "#children" do

    it { expect(pathname).to have(2).children }
    it { expect(pathname.children[0]).to be_an_instance_of(klass) }    

  end # context "#children"


end