# Author::  Nikolai Fedorov (nfedorov)

module ElFinder

  module Connector
  
    # Represents ElFinder connector to EJB service and other connector.
    class EjbAndOtherStorage < AbstractConnector

      DRIVER_ID = "EaO"

      # Valid commands to run.
      # @see #run
      VALID_COMMANDS = %w[archive duplicate edit extract mkdir mkfile open addinfo paste ping read rename resize rm tmb upload]

      # Default options for instances.
      # @see #initialize
      DEFAULT_OPTIONS = {
        :mime_handler => ElFinder::MimeType,
        :allow_dot_files => true,
        :home => 'EJB-and-Other-Home',
        :default_perms => { :read => true, :write => true, :rm => true, :hidden => false },
        :perms => [],
        :volume_id => DRIVER_ID,

      }

      # Initializes new instance.
      def initialize(options)
        @options = DEFAULT_OPTIONS.merge(options)

        raise(ArgumentError, "Missing required :driver_other option") unless @options.key?(:driver_other)
        raise(ArgumentError, "Missing required :root_other option") unless @options.key?(:root_other)

        @options[:volume_id] = "#{DRIVER_ID}#{@options[:index]}" unless @options[:index] == 0

        @one_connector = ElFinder::Connector::ConnectorFactory.createConnector('ejb').new(@options)
        two_connector_options = @options.merge({:root => @options[:root_other]})
        @two_connector = ElFinder::Connector::ConnectorFactory.createConnector(@options[:driver_other]).new(two_connector_options)

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

        if VALID_COMMANDS.include?(@params[:cmd])
          if ["open", "addinfo"].include? @params[:cmd]
            @headers, @response = @one_connector.run(@params)
          else 
            @headers, @response = @two_connector.run(@params)
          end
        else
          invalid_request
        end

        return @headers, @response
      end # of run

      #
      def close_remote_connection
        @one_connector.close_remote_connection
        @two_connector.close_remote_connection
      end

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
      def from_hash(hash)
        match = hash.match('\A(\S+\d?)_(.+\z)')
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


      def tree
        @one_connector.tree
      end


      ################################################################################
      protected

      
      ################################################################################
      private
      
      #
      def invalid_request
        @response[:error] = "Invalid command '#{@params[:cmd]}'"
      end # of invalid_request

      #
      def command_not_implemented
        @response[:error] = "Command '#{@params[:cmd]}' not yet implemented"
      end # of command_not_implemented

    end # of class

  end
end
