# Author::  Nikolai Fedorov (nfedorov)
require 'active_support/inflector'

module ElFinder
  module ConnectionPathnames

    class RestPathname < AbstractPathname

      DEFAULT_PARAMS = { 'withChildren' => true, 'withAttributes' => false }
      FOLDER_TYPE = "FOLDER"
      FILE_TYPE = "FILE"


      class << self

        private

        def define_attr_reader(*args)
          args.each do |method|
            define_method "#{method.to_s.underscore}" do
              @raw_json[method.to_s] 
            end
          end
        end

      end # self


      define_attr_reader :key, :name, :format, :fullPath

      #
      def mtime
        0
      end

      #
      def dir?
        node_type = @entry_metadata["nodeType"]
        return true  if node_type == FOLDER_TYPE
        return false if node_type == FILE_TYPE

        raise ArgumentError, "Incorrect 'nodeType'. Node type is '#{node_type}'."
      end

      #
      def filesize
        0
      end

      #
      def children
        path = (@path.to_s == ".") ? "" : "#{@path.to_s}/"
        childrens =  @entry_metadata["children"].nil? ? [] :  @entry_metadata["children"] 
        childrens.map { |item| self.class.new(@client_api, @root.to_s, path + item["name"], item) }
      end

      #
      def root
        item = @client_api.get params({ :path => '/' })
        self.class.new(@client_api, @root.to_s, path + item["name"], item)
      end

      #
      def ls(key = nil)
        key.nil? ? root.children : find_by_key(key).children
      end

      private

      #
      def params(params)
        DEFAULT_PARAMS.merge(params)
      end

      #
      def find_by_key(key)
        path = (@path.to_s == ".") ? "" : "#{@path.to_s}/"
        item = @client_api.get params({ :key => key })
        self.class.new(@client_api, @root.to_s, path + item["name"], item)
      end  

      #
      def get_entry_metadata
        @entry_metadata = @client_api.get params({ :path => fullpath })
        @entry_metadata
      end # get_entry_metadata

    end # of class Rest

  end # of module Pathnames
end # of module ElFinder
