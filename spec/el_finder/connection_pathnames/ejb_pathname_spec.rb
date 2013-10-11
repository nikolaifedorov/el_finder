require 'spec_helper'

describe ElFinder::ConnectionPathnames::EjbPathname do
  
  let(:klass) { ElFinder::ConnectionPathnames::EjbPathname }

  let(:null_object) { double('null object').as_null_object }

  let(:folder) {
    j_folder = double('JavaFolderEjbFake')

    j_folder
  }

  let(:file) {
    j_file = double('JavaFileEjbFake')

    j_file
  }

  let(:ejb_client_for_folder) do
    ejb_api = double('EjbFake')
    ejb_api.stub(:findFolder) { folder }
    ejb_api.stub(:getRoot) { null_object }
    ejb_api.stub(:getFolders) { [ null_object ] }
    ejb_api.stub(:getFiles) { [ null_object ] }

    ejb_api
  end

  let(:ejb_client_for_file) do
    ejb_api = double('EjbFake')
    ejb_api.stub(:findFolder) { nil }
    ejb_api.stub(:findFile) { nil }
    ejb_api.stub(:getRoot) { null_object }
    ejb_api.stub(:getFolders) { [ null_object ] }
    ejb_api.stub(:getFiles) { [ null_object ] }

    ejb_api
  end


  shared_examples "api" do

    context "#ejb_root" do
      it { expect(pathname.ejb_root).to eql(null_object) }
    end # context "#root"

    context "#folders" do
      it { expect(pathname.folders(null_object)).to eql([ null_object ]) }
    end # context "#folders"

    context "#files" do
      it { expect(pathname.files(null_object)).to eql([ null_object ]) }
    end # context "#files"

    context "#ls" do
      it "if argument is nill - calls #ejb_root" do
        pathname.should_receive(:ejb_root) { null_object }
        pathname.should_receive(:folders).with(null_object) { null_object }
        pathname.should_receive(:files).with(null_object) { null_object }

        pathname.ls
      end

      it { expect(pathname.ls).to eql([ null_object, null_object ]) }
    end # context "#ls"

    context "#children" do
      it { expect(pathname).to have(2).children }
      it { expect(pathname.children[0]).to be_an_instance_of(klass) }
    end # context "#children"

    context "#dir?" do
      it "#folders results should have #dir? equals true" do
        pathname.folders(null_object).each do |folder|
          expect(folder.dir?).to be_true
        end
      end

      it "#folders results should have #dir? equals false" do
        pathname.files(null_object).each do |file|
          expect(file.dir?).to be_false
        end
      end
    end # context "#dir?"

  end # shared_examples "api"
 

  context "folder from EJB" do
    let(:pathname) { klass.new(ejb_client_for_folder, "/") }
    include_examples "api"

    context "#dir?" do
      it { expect(pathname.dir?).to be_true }
    end # context "#dir?"

  end # context "folder from EJB"


  context "file from EJB" do
    let(:pathname) { klass.new(ejb_client_for_file, "/") }
    include_examples "api"

    context "#dir?" do
      it { expect(pathname.dir?).to be_false }
    end # context "#dir?"

  end # context "file from EJB"

end