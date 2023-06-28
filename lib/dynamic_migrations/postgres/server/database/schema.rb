# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        # This class represents a postgres schema. A schema is essentially a namespace within
        # a postgres database. Each schema is a collection of tables, functions and other
        # database objects.
        class Schema
          class ExpectedSymbolError < StandardError
          end

          class ExpectedDatabaseError < StandardError
          end

          include LoadedTables
          include ConfiguredTables

          attr_reader :database
          attr_reader :schema_name

          # initialize a new object to represent a postgres schema
          def initialize database, schema_name
            raise ExpectedDatabaseError, database unless database.is_a? Database
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            @database = database
            @schema_name = schema_name
            @configured_tables = {}
            @loaded_tables = {}
          end
        end
      end
    end
  end
end
