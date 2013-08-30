require 'pathname'
require 'net/ftp/list'

# Author::  Nikolai Fedorov (nfedorov)

module ElFinder
  module Pathnames

    class FTP
      attr_reader :root, :path

      #
      def initialize(ftp_connect, root, path = '.', ftp_entry = nil)
        @ftp_connect = ftp_connect
        @root = Pathname.new(root.to_s)
        @path = Pathname.new(path.to_s)
        @ftp_entry = ftp_entry.nil? ? self_ftp_entry : ftp_entry
      end # of initialize

      #
      def +(other)
        if other.is_a? ::ElFinder::Pathnames::FTP
          other = other.path
        end
        self.class.new(@ftp_connect, @root.to_s, (@path + other).to_s)
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
        @ftp_entry ? @ftp_entry.mtime : 0
      end

      #
      def dir?
        @ftp_entry ? @ftp_entry.dir? : true
      end

      #
      def filesize
        @ftp_entry ? @ftp_entry.filesize : 0
      end

      #
      def to_s
        cleanpath.to_s
      end # of to_s
      alias_method :to_str, :to_s


      # 
      # def child_directories(with_directory=true)

      #    realpath.children(with_directory).select{ |child| child.directory? }.map{|e| self.class.new(@root, e)}
      # end

      # 
      def children
        @ftp_connect.ls(fullpath.to_s).map{ |obj| Net::FTP::List.parse(obj) }.
          map{ |e| self.class.new(@ftp_connect, @root.to_s, @path.to_s + '/' + e.basename, e) }
      end

      private

      def self_ftp_entry
        restore_current_path = @ftp_connect.pwd
        
        @ftp_connect.chdir(fullpath.to_s)
        @ftp_connect.chdir("..")
        parent_path = @ftp_connect.pwd
        
        basename = fullpath.basename.to_s
        #restore_current_path.slice((parent_path.length + 1)..-1)

        @ftp_connect.chdir(restore_current_path)

        ftp_entry = @ftp_connect.ls(parent_path).map{ |obj| Net::FTP::List.parse(obj) }
        ftp_entry =  ftp_entry.select{ |e| e.basename == basename }

        ftp_entry.empty? ? nil : ftp_entry[0]
      end

    end # of class FTP

  end # of module Pathnames
end # of module ElFinder
