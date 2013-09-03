# Author::  Nikolai Fedorov (nfedorov)

module ElFinder
  module ConnectionPathnames

    class DropboxPathname < AbstractPathname

      #
      def mtime
        @entry_metadata ? @entry_metadata['modified'] : 0 
      end

      #
      def dir?
        @entry_metadata ? @entry_metadata['is_dir'] : true
      end

      #
      def filesize
        @entry_metadata ? @entry_metadata['bytes'] : 0
      end

      # 
      def children
        @entry_metadata['contents'].nil? ? [] : @entry_metadata['contents'].
                                                        map{ |e| self.class.new( 
                                                                                 @client_api, 
                                                                                 @root.to_s, 
                                                                                 path_from_root(e['path']) 
                                                                               )
                                                           }
      end


      private

      def path_from_root(path)
        path.slice((@root.to_s.length)..-1)
      end

      def get_entry_metadata
       @client_api.metadata(fullpath.to_s)
      end


    end # of class DropboxPathname

  end # of module ConnectionPathnames
end # of module ElFinder
