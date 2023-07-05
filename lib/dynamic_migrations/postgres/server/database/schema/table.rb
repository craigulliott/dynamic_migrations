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

            class PrimaryKeyDoesNotExistError < StandardError
            end

            include Columns
            include Validations
            include Indexes
            include ForeignKeyConstraints
            include UniqueConstraints

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
              @validations = {}
              @indexes = {}
              @foreign_key_constraints = {}
              @unique_constraints = {}
            end

            # returns true if this table has a description, otehrwise false
            def has_description?
              !@description.nil?
            end

            # add a primary key to this table
            def add_primary_key primary_key_name, column_names, **primary_key_options
              raise PrimaryKeyAlreadyExistsError if @primary_key
              columns = column_names.map { |column_name| column column_name }
              @primary_key = PrimaryKey.new source, self, columns, primary_key_name, **primary_key_options
            end

            # returns true if this table has a primary key, otherwise false
            def has_primary_key?
              !@primary_key.nil?
            end

            # returns a primary key if one exists, else raises an error
            def primary_key
              unless @primary_key
                raise PrimaryKeyDoesNotExistError
              end
              @primary_key
            end
          end
        end
      end
    end
  end
end
