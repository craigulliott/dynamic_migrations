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

            class ConstraintDoesNotExistError < StandardError
            end

            class ConstraintAlreadyExistsError < StandardError
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
              @constraints = {}
            end

            # returns true if this table has a description, otehrwise false
            def has_description?
              !@description.nil?
            end

            # returns the column object for the provided column name, and raises an
            # error if the column does not exist
            def column column_name
              raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
              raise ColumnDoesNotExistError unless has_column? column_name
              @columns[column_name]
            end

            # returns true if this table has a column with the provided name, otherwise false
            def has_column? column_name
              raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
              @columns.key? column_name
            end

            # returns an array of this tables columns
            def columns
              @columns.values
            end

            # adds a new column to this table, and returns it
            def add_column column_name, data_type, **column_options
              if has_column? column_name
                raise(ColumnAlreadyExistsError, "Column #{column_name} already exists")
              end
              @columns[column_name] = Column.new source, self, column_name, data_type, **column_options
            end

            # returns the constraint object for the provided constraint name, and raises an
            # error if the constraint does not exist
            def constraint constraint_name
              raise ExpectedSymbolError, constraint_name unless constraint_name.is_a? Symbol
              raise ConstraintDoesNotExistError unless has_constraint? constraint_name
              @constraints[constraint_name]
            end

            # returns true if this table has a constraint with the provided name, otherwise false
            def has_constraint? constraint_name
              raise ExpectedSymbolError, constraint_name unless constraint_name.is_a? Symbol
              @constraints.key? constraint_name
            end

            # returns an array of this tables constraints
            def constraints
              @constraints.values
            end

            # adds a new constraint to this table, and returns it
            def add_constraint constraint_name, column_names, check_clause
              if has_constraint? constraint_name
                raise(ConstraintAlreadyExistsError, "Constraint #{constraint_name} already exists")
              end
              columns = column_names.map { |column_name| column column_name }
              @constraints[constraint_name] = Constraint.new source, self, columns, constraint_name, check_clause
            end
          end
        end
      end
    end
  end
end
