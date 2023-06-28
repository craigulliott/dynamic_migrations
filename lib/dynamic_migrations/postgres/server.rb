# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    # This class represents a postgres server. A server can contain many databases.
    class Server
      attr_reader :host, :port, :username, :password

      # initialize a new object to represent a postgres server
      def initialize host, port, username, password
        @host = host
        @port = port
        @username = username
        @password = password
        @databases = {}
      end

      def add_database database_name
        raise ExpectedSymbolError, database_name unless database_name.is_a? Symbol
        @databases[database_name] = Database.new self, database_name
      end

      def database database_name
        raise ExpectedSymbolError, database_name unless database_name.is_a? Symbol
        @databases[database_name]
      end

      def databases
        @databases.values
      end
    end
  end
end
