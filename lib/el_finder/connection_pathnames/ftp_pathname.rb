require 'net/ftp/list'

# Author::  Nikolai Fedorov (nfedorov)

module ElFinder
  module ConnectionPathnames

    class FTPPathname < AbstractPathname

      #
      def mtime
        @entry_metadata ? @entry_metadata.mtime : 0
      end

      #
      def dir?
        @entry_metadata ? @entry_metadata.dir? : true
      end

      #
      def filesize
        @entry_metadata ? @entry_metadata.filesize : 0
      end

      # 
      def children
        @client_api.ls(fullpath.to_s).map{ |obj| Net::FTP::List.parse(obj) }.
          map{ |e| self.class.new(@client_api, @root.to_s, @path.to_s + '/' + e.basename, e) }
      end


      private

      def get_entry_metadata
        restore_current_path = @client_api.pwd
        
        @client_api.chdir(fullpath.to_s)
        @client_api.chdir("..")
        parent_path = @client_api.pwd
        
        basename = fullpath.basename.to_s

        @client_api.chdir(restore_current_path)

        entry_metadata = @client_api.ls(parent_path).map{ |obj| Net::FTP::List.parse(obj) }
        entry_metadata =  entry_metadata.select{ |e| e.basename == basename }

        entry_metadata.empty? ? nil : entry_metadata[0]
      end

    end # of class FTP

  end # of module Pathnames
end # of module ElFinder
