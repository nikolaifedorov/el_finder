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
        ls(@entry_metadata).map do |entry|
          name_entry = entry.dir? ? entry.getName() : entry.getFileName()
          self.class.new(@client_api, @root.to_s, path + name_entry, entry)
        end
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


      def set_attribute(key, value)
        unless dir?
          # TODO: I think it only tempory aproach.
          attribute = Java::OrgBiodtFs::Attribute.new
          attribute.setName(key)
          attribute.setValue(value)
          attribute.setFile(@entry_metadata)
          @client_api.setAttribute(attribute)
        end
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
