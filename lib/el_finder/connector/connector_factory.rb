# Author::  Nikolai Fedorov (nfedorov)

module ElFinder
  module Connector
  
    class ConnectorFactory

      DRIVER_ID_TO_CLASS = {
        'local'    => ElFinder::Connector::LocalFileSystem,
        'ftp'      => ElFinder::Connector::FtpStorage,
        'dropbox'  => ElFinder::Connector::DropboxStorage,
        'ejb'      => ElFinder::Connector::EjbConnector,
        'ejb_and'  => ElFinder::Connector::EjbAndOtherStorage,
        'rest'     => ElFinder::Connector::RestConnector,
        'rest_and' => ElFinder::Connector::RestAndOtherStorage
      }.freeze


      def self.createConnector(driver_id)
        raise(ArgumentError, "Invalid :driver_id option") unless DRIVER_ID_TO_CLASS.key?(driver_id)

        DRIVER_ID_TO_CLASS[driver_id]
      end
  
    end # ConnectorFactory

  end # module Connector
end # module ElFinder