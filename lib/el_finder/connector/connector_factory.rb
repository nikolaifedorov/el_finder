# Author::  Nikolai Fedorov (nfedorov)

module ElFinder
  module Connector
  
    class ConnectorFactory

      DRIVER_ID_TO_CLASS = {
        'local'   => ElFinder::Connector::LocalFileSystem,
        'ftp'     => ElFinder::Connector::FtpStorage,
        'dropbox' => ElFinder::Connector::DropboxStorage,
        'ejb'     => ElFinder::Connector::EjbConnector,
        'rest'    => ElFinder::Connector::RestConnector,
        'ejb_and' => ElFinder::Connector::EjbAndOtherStorage
      }.freeze


      def self.createConnector(driver_id)
        raise(ArgumentError, "Invalid :driver_id option") unless DRIVER_ID_TO_CLASS.key?(driver_id)

        DRIVER_ID_TO_CLASS[driver_id]
      end
  
    end # ConnectorFactory

  end # module Connector
end # module ElFinder