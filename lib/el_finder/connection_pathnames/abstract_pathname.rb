require 'pathname'

# Author::  Nikolai Fedorov (nfedorov)

module ElFinder
  module ConnectionPathnames

    class AbstractPathname
      
      attr_reader :root, :path

      #
      def initialize(connection_client, root, path = '.', entry_metadata = nil)
        @client_api = connection_client 
        @root = Pathname.new(root.to_s)
        @path = Pathname.new(path.to_s)
        @entry_metadata = entry_metadata.nil? ? get_entry_metadata() : entry_metadata
      end # of initialize

      #
      def +(other)
        if other.is_a? self.class
          other = other.path
        end
        self.class.new(@client_api, @root, (@path + other).to_s)
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
      def outside_of_root?
        !cleanpath.to_s.start_with?(@root.to_s)
      end # of outside_of_root?

      #
      def fullpath
        @path.nil? ? @root : @root + @path
      end # of fullpath

      #
      def cleanpath
        fullpath.cleanpath
      end # of cleanpath

      #
      def realpath
        fullpath.realpath
      end # of realpath

      #
      def basename(*args)
        @path.basename(*args)
      end # of basename

      #
      def basename_sans_extension
        @path.basename(@path.extname)
      end # of basename

      #
      def basename(*args)
        @path.basename(*args)
      end # of basename

      #
      def extname
        @path.nil? ? '' : @path.extname
      end # of extname

      #
      def to_s
        cleanpath.to_s
      end # of to_s
      alias_method :to_str, :to_s


      private

      #
      def get_entry_metadata
        nil
      end


    end

  end
end