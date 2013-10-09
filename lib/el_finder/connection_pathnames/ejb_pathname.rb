# Author::  Nikolai Fedorov (nfedorov)

module ElFinder
  module ConnectionPathnames

    class EjbPathname < AbstractPathname

      #
      def mtime
        0
      end

      #
      def dir?
        @entry_metadata.is_a? Java::OrgBiodtFs::Folder
      end

      #
      def filesize
        0
      end

      # 
      def children
        ls(@entry_metadata).map{ |e| self.class.new(@client_api, @root.to_s, @path.to_s + '/' + e.basename, e) }
      end

      def root
        @findFolder.getRoot()
      end

      def ls(folder = root)
        folders(folder) + files(folder)
      end

      def folders(folder)
        findFolder.getFolders(folder)
      end

      def files(folder)
        findFolder.getFiles(folder)
      end

      private

      def get_entry_metadata
        @entry_metadata = @client_api.findFolder(fullpath.to_s)
        @entry_metadata = @client_api.findFile(fullpath.to_s) if @entry_metadata.nil?

        @entry_metadata
      end

    end # of class EJB

  end # of module Pathnames
end # of module ElFinder
