# Author::  Nikolai Fedorov (nfedorov)

module ElFinder

  module Connector
  
    # Represents ElFinder connector to REST service.
    class RestConnector < AbstractConnector

      DRIVER_ID = "rest"

      # Valid commands to run.
      # @see #run
      VALID_COMMANDS = %w[open addinfo]

      # Default options for instances.
      # @see #initialize
      DEFAULT_OPTIONS = {
        :mime_handler => ElFinder::MimeType,
        :allow_dot_files => true,

        :disabled_commands => [],
        :upload_max_size => '50M',
        :archivers => {},
        :extractors => {},

        :home => 'EJB-Home',
        :default_perms => { :read => true, :write => true, :rm => true, :hidden => false },
        :perms => [],
        :volume_id => DRIVER_ID
      }

      # Initializes new instance.
      # @param [Hash] options Instance options. :url and :root options are required.
      # @option options [String] :url Entry point of ElFinder router.
      # @option options [String] :root Root directory of ElFinder directory structure.
      # @see DEFAULT_OPTIONS
      def initialize(options)
        @options = DEFAULT_OPTIONS.merge(options)

        raise(ArgumentError, "Missing required :root option") unless @options.key?(:root)

        raise(ArgumentError, "Missing required :rest_file option") unless @options.key?(:rest_file)

        raise(ArgumentError, "Mime Handler is invalid") unless mime_handler.respond_to?(:for)

        @service = RestFilesystem.init(@options[:rest_file].to_s)

        @root = ::ElFinder::ConnectionPathnames::RestPathname.new(@service, @options[:root].to_s)

        @options[:volume_id] = "#{@options[:volume_id]}#{@options[:index]}" unless @options[:index] == 0

        @headers = {}
        @response = {}
      end # of initialize


      # Runs request-response cycle.
      # @param [Hash] params Request parameters. :cmd option is required.
      # @option params [String] :cmd Command to be performed.
      # @see VALID_COMMANDS
      def run(params)
        @params = params.dup
        @headers = {}
        @response = {}
        @response[:errorData] = {}

        if VALID_COMMANDS.include?(@params[:cmd])

          target_params = (@params[:target] and !@params[:target].empty?) ? from_hash(@params[:target]).path : '.'
          @target = ::ElFinder::ConnectionPathnames::EjbPathname.new(@service, @root.to_s, target_params)

          if params[:targets]
            @targets = @params[:targets].map{|t| from_hash(t)}
          end

          send("_#{@params[:cmd]}")
        else
          invalid_request
        end

        @response.delete(:errorData) if @response[:errorData].empty?

        return @headers, @response
      end # of run

      #
      def close_remote_connection
        @context.close
      end

      #
      def volume_id
        @options[:volume_id]
      end


      #
      def to_hash(pathname)
        # note that '=' are removed
        hash = Base64.urlsafe_encode64(pathname.path.to_s).chomp.tr("=\n", "")
        "#{@options[:volume_id]}_#{hash}"
      end # of to_hash


      #
      def connector_id
        to_hash(@root)
      end


      #
      def from_hash(hash)
        match = hash.match('\A(\S+\d?)_(.+\z)')
        volume_id, hash = match[1], match[2] unless match.nil?
        
        # restore missing '='
        len = hash.length % 4
        hash += '==' if len == 1 or len == 2
        hash += '='  if len == 3

        decoded_hash = Base64.urlsafe_decode64(hash)
        decoded_hash = decoded_hash.respond_to?(:force_encoding) ? decoded_hash.force_encoding('utf-8') : decoded_hash
        # pathname = decoded_hash
        # pathname
        pathname = @root + decoded_hash

      rescue ArgumentError => e
        if e.message != 'invalid base64'
          raise
        end
        nil
      end # of from_hash


      def tree
        {
          :name => @options[:home],
          :hash => to_hash(@root),
          :dirs => tree_for(@root.children),
          :volumeid => @options[:volume_id]
        }.merge(perms_for(@root))
      end


      ################################################################################
      protected

      #
      def _open(target = nil)
        target ||= @target

        if target.nil?
          _open(@root)
          return
        end

        if perms_for(target)[:read] == false
          @response[:error] = 'Access Denied'
          return
        end

        @response[:cwd] = cwd_for(target)
        @response[:cdc] = target.children.
                          sort_by{|e| e.basename.to_s.downcase}.
                          map{|e| cdc_for(e)}.compact

        if @params[:tree]
          @response[:tree] = {
            :name => @options[:home],
            :hash => to_hash(@root),
            :dirs => tree_for(@root.children),
            :volumeid => @options[:volume_id]
          }.merge(perms_for(@root))
        end

        if @params[:init]
          @response[:disabled] = @options[:disabled_commands]
          @response[:params] = {
            :dotFiles => @options[:allow_dot_files],
            :uplMaxSize => @options[:upload_max_size],
            :archives => @options[:archivers].keys,
            :extract => @options[:extractors].keys,
            :url => @options[:url]
          }
          @response[:netDrivers] = [:ftp]
        end

      end # of open

      #
      def _addinfo

        key = @params['att_key']
        value = @params['att_v']

        @targets.to_a.each do |target|
          target.set_attribute(key, value)
        end
        
        @response["cmd"] = "addinfo"
        @response["status"] = "success"
      rescue Exception => e
        @response[:error] = "Invalid 'addinfo': #{e.message}"
      end # of addinfo
      
      ################################################################################
      private

      # 
      def cwd_for(pathname)
        {
          :name => pathname.basename.to_s,
          :hash => to_hash(pathname),
          :mime => 'directory',
          :rel => pathname.is_root? ? @options[:home] : (@options[:home] + '/' + pathname.path.to_s),
          :size => 0,
          :date => 0,
        }.merge(perms_for(pathname))
      end


      def cdc_for(pathname)
        response = {
          :name => pathname.basename.to_s,
          :hash => to_hash(pathname),
          :date => pathname.mtime,
        }
        response.merge! perms_for(pathname)

        if pathname.dir?
          response.merge!(
            :size => 0,
            :mime => 'directory'
          )
        else
          response.merge!(
            :size => pathname.filesize, 
            :mime => mime_handler.for(pathname.basename),
            :url => (@options[:url] + '/' + pathname.path.to_s)
          )

        end

        return response
      end


      #
      def tree_for(pathnames)
        pathnames.select{ |l| l.dir? }.
        sort_by{ |e| e.basename.to_s.downcase }.
        map do |child|
            {
              :name => child.basename.to_s,
              :hash => to_hash(child),
              :dirs => tree_for(child.children)
            }.merge(perms_for(child))
        end
      end # of tree_for


      #
      def perms_for(pathname, options = {})
        response = {}

        response[:read] = true
        response[:write] = true
        response[:rm] = true
        response[:hidden] = false

        response
      end # of perms_for

      #
      def mime_handler
        @options[:mime_handler]
      end
      
      #
      def invalid_request
        @response[:error] = "Invalid command '#{@params[:cmd]}'"
      end # of invalid_request

      #
      def command_not_implemented
        @response[:error] = "Command '#{@params[:cmd]}' not yet implemented"
      end # of command_not_implemented

    end # of class Rest

  end
end
