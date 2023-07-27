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

              class ExpectedDifferentTablesError < StandardError
              end

              class DuplicateColumnError < StandardError
              end

              attr_reader :table
              attr_reader :foreign_table
              attr_reader :name
              attr_reader :deferrable
              attr_reader :initially_deferred

              # initialize a new object to represent a foreign_key_constraint in a postgres table
              def initialize source, table, columns, foreign_table, foreign_columns, name, deferrable: false, initially_deferred: false
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

                if table.name == foreign_table.name && table.schema.name == foreign_table.schema.name
                  raise ExpectedDifferentTablesError
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

                raise ExpectedBooleanError, deferrable unless [true, false].include?(deferrable)
                @deferrable = deferrable

                raise ExpectedBooleanError, initially_deferred unless [true, false].include?(initially_deferred)
                @initially_deferred = initially_deferred
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

              def foreign_column_names
                @foreign_columns.keys
              end

              def foreign_schema_name
                @foreign_table.schema.name
              end

              def foreign_table_name
                @foreign_table.name
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
