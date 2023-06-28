# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          # This class represents a postgres table.
          class Table
            class ExpectedSymbolError < StandardError
            end

            class ExpectedSchemaError < StandardError
            end

            include LoadedColumns
            include ConfiguredColumns

            attr_reader :schema
            attr_reader :table_name

            # initialize a new object to represent a postgres table
            def initialize schema, table_name
              raise ExpectedSchemaError, schema unless schema.is_a? Schema
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              @schema = schema
              @table_name = table_name
              @configured_columns = {}
              @loaded_columns = {}
            end
          end
        end
      end
    end
  end
end
