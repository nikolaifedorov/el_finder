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
        @entry_metadata.dir?
      end


      #
      def filesize
        0
      end


      # 
      def children
        path = (@path.to_s == ".") ? "" : "#{@path.to_s}/"

        ls(@entry_metadata).map{ |e| self.class.new(@client_api, @root.to_s, path + e.getName(), e) }
      end


      def ejb_root
        @client_api.getRoot()
      end


      def ls(folder = ejb_root)
        folders(folder) + files(folder)
      end


      def folders(folder)
        folders = @client_api.getFolders(folder)
        folders.each do |folder|
          def folder.dir?
            true
          end
        end
        folders
      end


      def files(folder)
        files = @client_api.getFiles(folder)
        files.each do |file|
          def file.dir?
            false
          end
        end
        files
      end


      private

      def get_entry_metadata
        @entry_metadata = @client_api.findFolder(fullpath.to_s)
        if @entry_metadata.nil?
          @entry_metadata = @client_api.findFile(fullpath.to_s)

          def @entry_metadata.dir?
            false
          end

        else

          def @entry_metadata.dir?
            true
          end

        end
        
        @entry_metadata
      end # get_entry_metadata

    end # of class EJB

  end # of module Pathnames
end # of module ElFinder
