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

            class PrimaryKeyAlreadyExistsError < StandardError
            end

            include Columns
            include Validations
            include Indexes
            include ForeignKeyConstraints
            include Triggers
            include UniqueConstraints

            attr_reader :schema
            attr_reader :name
            attr_reader :description
            attr_reader :remote_foreign_key_constraints

            # initialize a new object to represent a postgres table
            def initialize source, schema, name, description: nil
              super source

              raise ExpectedSchemaError, schema unless schema.is_a? Schema
              @schema = schema

              raise ExpectedSymbolError, name unless name.is_a? Symbol
              @name = name

              unless description.nil?
                raise ExpectedStringError, description unless description.is_a? String
                @description = description.strip
                @description = nil if description == ""
              end

              @columns = {}
              @validations = {}
              @indexes = {}
              @foreign_key_constraints = {}
              @remote_foreign_key_constraints = []
              @triggers = {}
              @unique_constraints = {}
            end

            # returns true if this table has a description, otehrwise false
            def has_description?
              !@description.nil?
            end

            # add a primary key to this table
            def add_primary_key name, column_names, **primary_key_options
              raise PrimaryKeyAlreadyExistsError if @primary_key
              columns = column_names.map { |column_name| column column_name }
              @primary_key = PrimaryKey.new source, self, columns, name, **primary_key_options
            end

            # returns true if this table has a primary key, otherwise false
            def has_primary_key?
              !@primary_key.nil?
            end

            # returns a primary key if one exists, else raises an error
            def primary_key
              pk = @primary_key
              unless pk
                raise PrimaryKeyDoesNotExistError
              end
              pk
            end
          end
        end
      end
    end
  end
end
