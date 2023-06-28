# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        # This class represents a postgres schema. A schema is essentially a namespace within
        # a postgres database. Each schema is a collection of tables, functions and other
        # database objects.
        class Schema < Source
          class ExpectedDatabaseError < StandardError
          end

          class TableAlreadyExistsError < StandardError
          end

          class TableDoesNotExistError < StandardError
          end

          attr_reader :database
          attr_reader :schema_name

          # initialize a new object to represent a postgres schema
          def initialize source, database, schema_name
            super source
            raise ExpectedDatabaseError, database unless database.is_a? Database
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            @database = database
            @schema_name = schema_name
            @tables = {}
          end

          # create and add a new table from a provided table name
          def add_table table_name
            raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
            if has_table? table_name
              raise(TableAlreadyExistsError, "Table #{table_name} already exists")
            end
            @tables[table_name] = Table.new source, self, table_name
          end

          # return a table by its name, raises an error if the table does not exist
          def table table_name
            raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
            raise TableDoesNotExistError unless has_table? table_name
            @tables[table_name]
          end

          # returns true/false representing if a table with the provided name exists
          def has_table? table_name
            raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
            @tables.key? table_name
          end

          # returns an array of all tables in the schema
          def tables
            @tables.values
          end
        end
      end
    end
  end
end
