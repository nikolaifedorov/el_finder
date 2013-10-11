#
# http://elrte.org/redmine/projects/elfinder/wiki/Client-Server_Protocol_EN
#
require 'base64'

# Author::  Nikolai Fedorov (nfedorov)

module ElFinder

  # Represents ElFinder adapter on Rails side.
  class Adapter


    # API version number
    VERSION_API = '2.0';

    # Valid commands to run.
    # @see #run
    VALID_COMMANDS = %w[archive duplicate edit extract mkdir mkfile open paste ping read rename resize rm tmb upload]


    # Default options for instances.
    # @see #initialize
    DEFAULT_OPTIONS = {
      :mime_handler => ElFinder::MimeType,
      :image_handler => ElFinder::Image,
      :original_filename_method => lambda { |file| file.original_filename.respond_to?(:force_encoding) ? file.original_filename.force_encoding('utf-8') : file.original_filename },
      :disabled_commands => [],
      :allow_dot_files => true,
      :upload_max_size => '50M',
      :upload_file_mode => 0644,
      :archivers => {},
      :extractors => {},
      :home => 'Home',
      :default_perms => { :read => true, :write => true, :rm => true, :hidden => false },
      :perms => [],
      :thumbs => false,
      :thumbs_directory => '.thumbs',
      :thumbs_size => 48,
      :thumbs_at_once => 5
    }


    # Initializes new instance.
    def initialize(options)
      # @options = DEFAULT_OPTIONS.merge(options)

      raise(ArgumentError, "Missing required :roots option") unless options.key?(:roots)

      # Storages (root dirs)
      @storages = {}

      # TODO: think about index.
      options[:roots].each_with_index do |current_root, index|
        options = DEFAULT_OPTIONS.merge(current_root)
        options[:index] = index
        # connector = ElFinder::Connector::LocalFileSystem.new(options)
        raise(ArgumentError, "Missing required :driver option") unless options.key?(:driver)

        connector = ElFinder::Connector::ConnectorFactory.createConnector(options[:driver]).new(options)
        @storages[connector.volume_id] = connector
      end

    end # of initialize


    # Runs request-response cycle.
    # @param [Hash] params Request parameters. :cmd option is required.
    # @option params [String] :cmd Command to be performed.
    # @see VALID_COMMANDS
    def run(params)
      @params = params.dup

      if VALID_COMMANDS.include?(@params[:cmd])

        connector = connector_from_params(@params)

        # send("_#{@params[:cmd]}")
        @headers, @response = connector.run(@params)

        if @params[:init]
          @response[:tree] = tree
          @response[:netDrivers] = [:ftp]
        end

      else
        invalid_request
      end

      return @headers, @response
    # rescue Exception => e  
    #   puts e.message  
    #   puts e.backtrace
    end # of run

    #
    def close_all
      @storages.values.each do |connector|
        connector.close_remote_connection
      end
    end

    #
    def connector_from_params(params)
      # @current = params[:current] ? from_hash(@params[:current]) : from_hash(default_connector_hash)
      # @target = (@params[:target] and !@params[:target].empty?) ? from_hash(@params[:target]) : from_hash(default_connector_hash)

      # TODO: think about volume_id
      connector = (params[:target] and !params[:target].blank?) ? @storages[volume_id_by_hash(params[:target])] : @storages[@storages.keys.first]
    end # of from_hash


    def volume_id_by_hash(hash)
      match = hash.match('\A(\S+\d?)_(.+\z)')
      volume_id = match[1] unless match.nil?

      volume_id
    end


    def tree
      tree = []
      @storages.values.each do |connector|
        tree << connector.tree
      end
      tree
    end

    # TODO:REFACTORING: nfedorov. on future.
    # cwd : Current Working Directory - information about the current directory.
    # Returns hash:
    # {
    #     "name"   : "Images",             // (String) name of file/dir. Required
    #     "hash"   : "l0_SW1hZ2Vz",        // (String) hash of current file/dir path, first symbol must be letter, symbols before _underline_ - volume id, Required. 
    #     "phash"  : "l0_Lw",              // (String) hash of parent directory. Required except roots dirs.
    #     "mime"   : "directory",          // (String) mime type. Required.
    #     "ts"     : 1334163643,           // (Number) file modification time in unix timestamp. Required.
    #     "date"   : "30 Jan 2010 14:25",  // (String) last modification time (mime). Depricated but yet supported. Use ts instead.
    #     "size"   : 12345,                // (Number) file size in bytes
    #     "dirs"   : 1,                    // (Number) Only for directories. Marks if directory has child directories inside it. 0 (or not set) - no, 1 - yes. Do not need to calculate amount.
    #     "read"   : 1,                    // (Number) is readable
    #     "write"  : 1,                    // (Number) is writable
    #     "locked" : 0,                    // (Number) is file locked. If locked that object cannot be deleted and renamed
    #     "tmb"    : 'bac0d45b625f8d4633435ffbd52ca495.png' // (String) Only for images. Thumbnail file name, if file do not have thumbnail yet, but it can be generated than it must have value "1"
    #     "alias"  : "files/images",       // (String) For symlinks only. Symlink target path.
    #     "thash"  : "l1_c2NhbnMy",        // (String) For symlinks only. Symlink target hash.
    #     "dim"    : "640x480"             // (String) For images - file dimensions. Optionally.
    #     "volumeid" : "l1_"               // (String) Volume id. For root dir only.
    # }
    # def cwd_for(directory)
    #   {
    #     :name   => directory.name,
    #     :hash   => directory.hash,
    #     :phash  => directory.parent.hash,
    #     :mime   => directory.mime,
    #     :ts     => directory.timestamp,
    #     :size   => directory.size,
    #     :dirs   => directory.has_child,
    #   }.merge(perms_for(directory))
    # end

   
    #
    def invalid_request
      @response[:error] = "Invalid command '#{@params[:cmd]}'"
    end # of invalid_request



    #
    def command_not_implemented
      @response[:error] = "Command '#{@params[:cmd]}' not yet implemented"
    end # of command_not_implemented

  end # of class Adapter
end # of module ElFinder
