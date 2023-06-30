# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          # This class represents a postgres table.
          class Table < Source
            class ExpectedSchemaError < StandardError
            end

            class ColumnDoesNotExistError < StandardError
            end

            class ColumnAlreadyExistsError < StandardError
            end

            attr_reader :schema
            attr_reader :table_name
            attr_reader :description

            # initialize a new object to represent a postgres table
            def initialize source, schema, table_name, description = nil
              super source
              raise ExpectedSchemaError, schema unless schema.is_a? Schema
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              unless description.nil?
                raise ExpectedStringError, description unless description.is_a? String
                @description = description
              end
              @schema = schema
              @table_name = table_name
              @columns = {}
            end

            def has_description?
              !@description.nil?
            end

            def column column_name
              raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
              raise ColumnDoesNotExistError unless has_column? column_name
              @columns[column_name]
            end

            def has_column? column_name
              raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
              @columns.key? column_name
            end

            def columns
              @columns.values
            end

            def add_column column_name, data_type, **column_options
              raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
              if has_column? column_name
                raise(ColumnAlreadyExistsError, "Column #{column_name} already exists")
              end
              @columns[column_name] = Column.new source, self, column_name, data_type, **column_options
            end
          end
        end
      end
    end
  end
end
