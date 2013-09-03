require 'net/ftp'

# Author::  Nikolai Fedorov (nfedorov)

module ElFinder

  module Connector
  
    # Represents ElFinder connector to ftp server.
    class FtpStorage

      DRIVER_ID = "f"

      # Valid commands to run.
      # @see #run
      VALID_COMMANDS = %w[open]

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
        :thumbs_at_once => 5,
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

        raise(ArgumentError, "Missing required :url option") unless @options.key?(:url)
        raise(ArgumentError, "Missing required :login option") unless @options.key?(:login)
        raise(ArgumentError, "Missing required :password option") unless @options.key?(:password)

        raise(ArgumentError, "Mime Handler is invalid") unless mime_handler.respond_to?(:for)
        raise(ArgumentError, "Image Handler is invalid") unless image_handler.nil? || ([:size, :resize, :thumbnail].all?{|m| image_handler.respond_to?(m)})

        # @root = @options[:root]
        @ftp = Net::FTP.new(@options[:url])
        @ftp.passive = true
        @ftp.login(@options[:login], @options[:password])
        @ftp.chdir(@options[:root])

        @root = ::ElFinder::ConnectionPathnames::FTPPathname.new(@ftp, @options[:root].to_s)

        @pwd = @ftp.pwd


        @options[:volume_id] = "#{DRIVER_ID}#{@options[:index]}" unless @options[:index] == 0

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

          # @current = @params[:current] ? from_hash(@params[:current]) : nil

          target_params = (@params[:target] and !@params[:target].empty?) ? from_hash(@params[:target]) : '.'
          @target = ::ElFinder::ConnectionPathnames::FTPPathname.new(@ftp, @root.to_s, target_params)
          # if params[:targets]
          #   @targets = @params[:targets].map{|t| from_hash(t)}
          # end

          send("_#{@params[:cmd]}")
        else
          invalid_request
        end

        @response.delete(:errorData) if @response[:errorData].empty?

        return @headers, @response
      end # of run


      #
      def volume_id
        @options[:volume_id]
      end


      #
      def to_hash(pathname)
        # note that '=' are removed
        hash = Base64.urlsafe_encode64(pathname.to_s).chomp.tr("=\n", "")
        "#{@options[:volume_id]}_#{hash}"
      end # of to_hash


      #
      def connector_id
        to_hash(@root)
      end


      #
      def from_hash(hash)
        match = hash.match('\A(\S\d?)_(.+\z)')
        volume_id, hash = match[1], match[2] unless match.nil?
        
        # restore missing '='
        len = hash.length % 4
        hash += '==' if len == 1 or len == 2
        hash += '='  if len == 3

        decoded_hash = Base64.urlsafe_decode64(hash)
        decoded_hash = decoded_hash.respond_to?(:force_encoding) ? decoded_hash.force_encoding('utf-8') : decoded_hash
        pathname = decoded_hash

        pathname

      rescue ArgumentError => e
        if e.message != 'invalid base64'
          raise
        end
        nil
      end # of from_hash


      # @!attribute [w] options
      # Options setter.
      # @param value [Hash] Options to be merged with instance ones.
      # @return [Hash] Updated options.
      # def options=(value = {})
      #   value.each_pair do |k, v|
      #     @options[k.to_sym] = v
      #   end
      #   @options
      # end # of options=


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

        # children_target_ftp_list = ftp_ls(target)

        @response[:cwd] = cwd_for(target)
        @response[:cdc] = target.children.
                          sort_by{|e| e.basename.to_s.downcase}.
                          map{|e| cdc_for(e)}.compact

        if @params[:tree]
          # root_ftp_list = ftp_ls(@root)          
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

          # @response[:error] = "Directory does not exist"
          # _open(@root) if File.directory?(@root)

      end # of open

      
      ################################################################################
      private

      # def ftp_ls(path)
      #   nornalize_list = @ftp.ls(path).map{ |obj| parse_ls_unix_like_format(obj) }
      #   @pwd = path

      #   nornalize_list
      # end

      #
      def upload_max_size_in_bytes
        bytes = @options[:upload_max_size]
        if bytes.is_a?(String) && bytes.strip =~ /(\d+)([KMG]?)/
          bytes = $1.to_i
          unit = $2
          case unit
            when 'K'
              bytes *= 1024
            when 'M'
              bytes *= 1024 * 1024
            when 'G'
              bytes *= 1024 * 1024 * 1024
          end
        end
        bytes.to_i
      end

      #
      # Avalable params:
      # type
      # mode
      # number
      # owner
      # group
      # size
      # mod_time
      # path
      #
      # def parse_ls_unix_like_format(str="")
      #   str = str.force_encoding('utf-8')
      #   reg = /^(?<type>.{1})(?<mode>\S+)\s+(?<number>\d+)\s+(?<owner>\S+)\s+(?<group>\S+)\s+(?<size>\d+)\s+(?<mod_time>.{12})\s+(?<path>.+)$/
      #   str.match(reg)
      # end

      #
      def thumbnail_for(pathname)
        @thumb_directory + "#{to_hash(pathname)}.png"
      end


      def mime_handler
        @options[:mime_handler]
      end

      #
      def image_handler
        @options[:image_handler]
      end


      # 
      def cwd_for(pathname)

        {
          :name => pathname.basename.to_s,
          :hash => to_hash(pathname),
          :mime => 'directory',
          :rel => pathname == @root ? @options[:home] : (@options[:home] + '/' + pathname.to_s),
          :size => 0,
          :date => 0,
        }.merge(perms_for(pathname))
      end


      def cdc_for(pathname)
        #return nil if @options[:thumbs] && pathname.to_s == @thumb_directory.to_s
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
            :url => (@options[:url] + '/' + pathname.to_s)
          )

        end

        return response
      end

      #
      def tree_for(pathnames)
        pathnames.select{ |l| l.dir? }.
        sort_by{ |e| e.basename.to_s.downcase }.
        map { |child|
            {:name => child.basename.to_s,
             :hash => to_hash(child),
             # :dirs => [],
             :dirs => tree_for(child.children),
             # :dirs => tree_for(child.path),
            }.merge(perms_for(child))
        }
      end # of tree_for

      #
      def perms_for(pathname, options = {})
        response = {}

        response[:read] = true
        # response[:read] &&= specific_perm_for(pathname, :read)
        # response[:read] &&= @options[:default_perms][:read] 

        response[:write] = true
        # response[:write] &&= specific_perm_for(pathname, :write) 
        # response[:write] &&= @options[:default_perms][:write]

        response[:rm] = true
        # response[:rm] &&= specific_perm_for(pathname, :rm)
        # response[:rm] &&= @options[:default_perms][:rm]

        response[:hidden] = false
        # response[:hidden] ||= specific_perm_for(pathname, :hidden)
        # response[:hidden] ||= @options[:default_perms][:hidden]

        response
      end # of perms_for

      
      #
      def invalid_request
        @response[:error] = "Invalid command '#{@params[:cmd]}'"
      end # of invalid_request

      #
      def command_not_implemented
        @response[:error] = "Command '#{@params[:cmd]}' not yet implemented"
      end # of command_not_implemented

    end # of class FTP_Storage

  end
end
