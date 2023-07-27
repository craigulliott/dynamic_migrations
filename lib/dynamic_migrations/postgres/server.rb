# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    # This class represents a postgres server. A server can contain many databases.
    class Server
      class DatabaseAlreadyExistsError < StandardError
      end

      attr_reader :host, :port, :username, :password

      # initialize a new object to represent a postgres server
      def initialize host, port, username, password
        @host = host
        @port = port
        @username = username
        @password = password
        @databases = {}
      end

      def add_database name
        raise ExpectedSymbolError, name unless name.is_a? Symbol
        raise DatabaseAlreadyExistsError, "database `#{name}` already exists" if @databases.key? name
        @databases[name] = Database.new self, name
      end

      def database name
        raise ExpectedSymbolError, name unless name.is_a? Symbol
        @databases[name]
      end

      def databases
        @databases.values
      end
    end
  end
end
