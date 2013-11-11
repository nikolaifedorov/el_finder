require 'spec_helper'

describe ElFinder::ConnectionPathnames::RestPathname do
  
  let(:klass) { ElFinder::ConnectionPathnames::RestPathname }

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

  let(:folder_without_children) {
    {
      'key' => "d061f348-64a5-47cf-bad3-e273dd4e06a6",
      'name' => "root",
      'format' => nil,
      'size' => 0,
      'nodeType' => "FOLDER",
      'fullPath' => "/",
      'children' => nil,
      'attributes' => []
    }
  }

  let(:params_with_forder_path) { { 'withChildren' => true, 'withAttributes' => true, :path => folder['fullPath'] } }
  let(:params_with_folder_key) { { 'withChildren' => true, 'withAttributes' => true, :key => folder['key'] } }

  let(:rest_client_for_folder) do
    rest_api = double('RESTFaker')
    rest_api.stub(:get).with( params_with_forder_path ) { folder }
    rest_api.stub(:get).with( params_with_folder_key ) { folder }
    rest_api.stub(:get) { folder }
    rest_api
  end

  let(:params_with_file_path) { { 'withChildren' => true, 'withAttributes' => true, :path => file['fullPath']}}
  let(:params_with_file_key) { { 'withChildren' => true, 'withAttributes' => true, :key => file['key'] } }

  let(:rest_client_for_file) do
    rest_api = double('RESTFaker')
    rest_api.stub(:get).with( params_with_file_path ) { file }
    rest_api.stub(:get).with( params_with_file_key ) { file }
    rest_api.stub(:get) { file }
    rest_api
  end

  let!(:pathname_folder) { klass.new(rest_client_for_folder, folder["fullPath"]) }
  let!(:children_pathname_folder) { klass.new(rest_client_for_folder, pathname_folder.root.to_s, pathname_folder.path + file["name"], file) }

  let!(:pathname_file) { klass.new(rest_client_for_file, folder["fullPath"]) }


  shared_examples "api" do

    describe '#rest_root' do
      it 'returns correct pathname' do
        klass.stub(:new).with(rest_client, root) { root_pathname }
        expect(pathname.rest_root).to eq(root_pathname)
      end
    end # #rest_root


    describe '#ls' do
      context 'when argument is nill' do
        it 'invokes #rest_root' do
          root_pathname.stub(:children) { result_children_for_root_pathname }
          pathname.should_receive(:rest_root) { root_pathname }
          expect(pathname.ls).to eq( result_children_for_root_pathname )
        end
      end

      context 'when argument is not nill' do
        it 'invokes #find_by_key' do
          root_pathname.stub(:children) { result_children_for_root_pathname }
          pathname.should_receive(:find_by_key).with(item['key']) { root_pathname }
          expect( pathname.ls(item['key']) ).to eql( result_children_for_root_pathname )
        end

        it 'returns RestPathname object for json' do
          klass.stub(:new).with(rest_client, root) { root_pathname }
          klass.stub(:new).with(rest_client, root, path_for_find_by_key, item) { root_pathname }
          klass.stub(:new).with(rest_client, root, path_for_children, item_child) { children_pathname }
          expect( pathname.ls(item['key']) ).to eq( result_children_for_root_pathname )
        end
      end # when argument is not nill
    end # #ls


    describe '#key' do
      it { expect( pathname.key ).to eql( item['key'] ) }
    end


    describe '#name' do
      it { expect( pathname.name ).to eql( item['name'] ) }
    end


    describe '#format' do
      it { expect( pathname.format ).to eql( item['format'] ) }
    end


    describe '#full_path' do
      it { expect( pathname.full_path ).to eql( item['fullPath'] ) }
    end

  end # shared_examples "api"
 

  context 'folder from REST' do
    let(:rest_client) { rest_client_for_folder }

    let(:root) { "/" }
    let(:path_for_find_by_key) { "." }
    let(:path_for_children) { "example2.gff" }
    
    let(:pathname) { klass.new(rest_client, root) }
    let(:root_pathname) { pathname_folder }
    let(:children_pathname) { children_pathname_folder }
    let(:result_children_for_root_pathname) { [ children_pathname ] }

    let(:item) { folder }
    let(:item_child) { file }
    let(:item_without_children) { folder_without_children }

    include_examples "api"

    describe "#children" do

      it { expect(pathname).to have(1).children }

      it { expect(pathname.children[0]).to be_an_instance_of(klass) }
     
      it 'returns array RestPathname objects from json' do
        klass.stub(:new) { children_pathname }
        klass.stub(:new).with(rest_client , root) { root_pathname }
        expect(pathname.children[0]).to eql(children_pathname)
      end

      it 'sets correct path for child' do
        klass.stub(:new) { children_pathname }
        klass.stub(:new).with(rest_client, root) { root_pathname }
        expect(pathname.children[0].path).to eql(children_pathname.path)
      end

      context 'when no children' do
        it 'returns empty array' do
          rest_client.stub(:get) { item_without_children }

          expect(pathname.children).to eql([])
        end
      end
    end # #children

    context '#dir?' do
      it { expect(pathname.dir?).to be_true }
    end # dir?

  end # folder from REST


  context "file from REST" do
    let(:rest_client) { rest_client_for_file }

    let(:root) { "/" }
    let(:path_for_find_by_key) { "example2.gff" }
    let(:path_for_children) { nil }
    
    let(:pathname) { klass.new(rest_client, root) }
    let(:root_pathname) { pathname_file }
    let(:children_pathname) { nil }
    let(:result_children_for_root_pathname) { [] }

    let(:item) { file }
    let(:item_child) { file }
    let(:item_without_children) { folder_without_children }

    include_examples "api"


    describe "#children" do
      it { expect(pathname).to have(0).children }

      it { expect(pathname.children).to be_an_instance_of(Array) }
     
      it 'returns empty array' do
        expect(pathname.children).to eql( [] )
      end
    end # #children

    context "#dir?" do
      it { expect(pathname.dir?).to be_false }
    end #  #dir?

  end # file from REST

end # RestPathname