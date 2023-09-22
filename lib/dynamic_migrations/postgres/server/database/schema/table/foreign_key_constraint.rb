# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a postgres foreign key constraint
            class ForeignKeyConstraint < Source
              class ExpectedTableError < StandardError
              end

              class ExpectedArrayOfColumnsError < StandardError
              end

              class DuplicateColumnError < StandardError
              end

              class UnexpectedReferentialActionError < StandardError
              end

              attr_reader :table
              attr_reader :foreign_table
              attr_reader :name
              attr_reader :deferrable
              attr_reader :initially_deferred
              attr_reader :on_delete
              attr_reader :on_update
              attr_reader :description

              # initialize a new object to represent a foreign_key_constraint in a postgres table
              def initialize source, table, columns, foreign_table, foreign_columns, name, description: nil, deferrable: false, initially_deferred: false, on_delete: :no_action, on_update: :no_action
                super source

                raise ExpectedTableError, table unless table.is_a? Table
                raise ExpectedTableError, foreign_table unless foreign_table.is_a? Table

                # assert that the provided columns is an array
                unless columns.is_a?(Array) && columns.count > 0
                  raise ExpectedArrayOfColumnsError
                end

                # assert that the provided foreign columns is an array
                unless foreign_columns.is_a?(Array) && foreign_columns.count > 0
                  raise ExpectedArrayOfColumnsError
                end

                # tables must be set before the columns are added
                @table = table
                @foreign_table = foreign_table

                @columns = {}
                columns.each do |column|
                  add_column column
                end

                @foreign_columns = {}
                foreign_columns.each do |column|
                  add_column column, true
                end

                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @name = name

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description.strip
                  @description = nil if description == ""
                end

                raise ExpectedBooleanError, deferrable unless [true, false].include?(deferrable)
                @deferrable = deferrable

                raise ExpectedBooleanError, initially_deferred unless [true, false].include?(initially_deferred)
                @initially_deferred = initially_deferred

                raise UnexpectedReferentialActionError, on_delete unless [:no_action, :restrict, :cascade, :set_null, :set_default].include?(on_delete)
                @on_delete = on_delete

                raise UnexpectedReferentialActionError, on_update unless [:no_action, :restrict, :cascade, :set_null, :set_default].include?(on_update)
                @on_update = on_update
              end

              # return true if this has a description, otherwise false
              def has_description?
                !@description.nil?
              end

              def columns
                @columns.values
              end

              def column_names
                @columns.keys
              end

              def foreign_columns
                @foreign_columns.values
              end

              def foreign_schema_name
                @foreign_table.schema.name
              end

              def foreign_table_name
                @foreign_table.name
              end

              def foreign_column_names
                @foreign_columns.keys
              end

              def differences_descriptions other_foreign_key_constraint
                method_differences_descriptions other_foreign_key_constraint, [
                  :column_names,
                  :foreign_schema_name,
                  :foreign_table_name,
                  :foreign_column_names,
                  :deferrable,
                  :initially_deferred,
                  :on_delete,
                  :on_update
                ]
              end

              private

              # used internally to set the columns from this objects initialize method
              def add_column column, foreign = false
                if foreign
                  cs = @foreign_columns
                  t = @foreign_table
                else
                  cs = @columns
                  t = @table
                end

                # assert that the provided dsl name is an array of Columns
                unless column.is_a? Column
                  raise ExpectedArrayOfColumnsError
                end

                # assert that the provided column exists within this foreign_key_constraints table
                unless t.has_column? column.name
                  raise ExpectedArrayOfColumnsError, "One or more columns do not exist in this foreign_key_constraints table"
                end

                if cs.key? column.name
                  raise(DuplicateColumnError, "Column #{column.name} already exists")
                end

                cs[column.name] = column
              end
            end
          end
        end
      end
    end
  end
end
