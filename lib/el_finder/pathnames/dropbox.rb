require 'pathname'

# Author::  Nikolai Fedorov (nfedorov)

module ElFinder
  module Pathnames

    class Dropbox
      attr_reader :root, :path

      #
      def initialize(dropbox_client, root, path = '.', dropbox_metadata_raw = nil)
        @dropbox_client = dropbox_client
        @root = Pathname.new(root)
        @path = Pathname.new(path)
        @dropbox_metadata_raw = dropbox_metadata_raw.nil? ? self_dropbox_metadata_raw : dropbox_metadata_raw
      end # of initialize

      #
      def +(other)
        if other.is_a? ::ElFinder::Pathnames::Dropbox
          other = other.path
        end
        self.class.new(@dropbox_client, @root, (@path + other).to_s)
      end # of +

      #
      def is_root?
        @path.to_s == '.'
      end

      #
      def absolute?
        @path.absolute?
      end # of absolute?

      #
      def relative?
        @path.relative?
      end # of relative?

      #
      def fullpath
        @path.nil? ? @root : @root + @path
      end # of fullpath

      #
      def cleanpath
        fullpath.cleanpath
      end # of cleanpath

      #
      def basename(*args)
        @path.basename(*args).to_s
      end # of basename

      #
      def basename_sans_extension
        @path.basename(@path.extname)
      end # of basename_sans_extension

      #
      def extname
        @path.nil? ? '' : @path.extname
      end # of extname

      #
      def mtime
        @dropbox_metadata_raw ? Time.parse(@dropbox_metadata_raw['modified']).to_i : 0 
      end

      #
      def dir?
        @dropbox_metadata_raw ? @dropbox_metadata_raw['is_dir'] : true
      end

      #
      def filesize
        @dropbox_metadata_raw ? @dropbox_metadata_raw['bytes'] : 0
      end

      #
      def to_s
        cleanpath.to_s
      end # of to_s
      alias_method :to_str, :to_s


      # 
      def children
        @dropbox_metadata_raw['contents'].
          map{ |e| self.class.new(@dropbox_client, @root.to_s, path_from_root(e['path']), e) }
      end


      private

      def path_from_root(path)
        path.slice((@root.to_s.length + 1)..-1)
      end

      def self_dropbox_metadata_raw
        @dropbox_client.metadata(fullpath.to_s)
      end

    end # of class Dropbox

  end # of module Pathnames
end # of module ElFinder
