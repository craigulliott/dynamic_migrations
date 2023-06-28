# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      # This class represents a postgres database. A database can contain many different
      # schemas.
      class Database
        class ExpectedSymbolError < StandardError
        end

        class ExpectedServerError < StandardError
        end

        include Connection
        include LoadedSchemas
        include ConfiguredSchemas

        attr_reader :server
        attr_reader :database_name

        # initialize a new object to represent a postgres database
        def initialize server, database_name
          raise ExpectedServerError, server unless server.is_a? Server
          raise ExpectedSymbolError, database_name unless database_name.is_a? Symbol
          @server = server
          @database_name = database_name
          @configured_schemas = {}
          @loaded_schemas = {}
        end
      end
    end
  end
end
