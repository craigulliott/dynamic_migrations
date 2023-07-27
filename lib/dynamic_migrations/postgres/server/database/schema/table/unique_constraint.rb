# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a postgres table unique_constraint
            class UniqueConstraint < Source
              INDEX_TYPES = [:btree, :hash, :gist, :gin, :bring, :spgist]

              class ExpectedTableError < StandardError
              end

              class ExpectedArrayOfColumnsError < StandardError
              end

              class UnexpectedIndexTypeError < StandardError
              end

              class UnexpectedOrderError < StandardError
              end

              class UnexpectedNullsPositionError < StandardError
              end

              class DuplicateColumnError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :index_type
              attr_reader :deferrable
              attr_reader :initially_deferred

              # initialize a new object to represent a unique_constraint in a postgres table
              def initialize source, table, columns, name, index_type: :btree, deferrable: false, initially_deferred: false
                super source
                raise ExpectedTableError, table unless table.is_a? Table
                @table = table
                @columns = {}

                # assert that the provided columns is an array
                unless columns.is_a?(Array) && columns.count > 0
                  raise ExpectedArrayOfColumnsError
                end

                columns.each do |column|
                  add_column column
                end

                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @name = name

                raise UnexpectedIndexTypeError, index_type unless INDEX_TYPES.include?(index_type)
                @index_type = index_type

                raise ExpectedBooleanError, deferrable unless [true, false].include?(deferrable)
                @deferrable = deferrable

                raise ExpectedBooleanError, initially_deferred unless [true, false].include?(initially_deferred)
                @initially_deferred = initially_deferred
              end

              # return an array of this unique_constraints columns
              def columns
                @columns.values
              end

              def column_names
                @columns.keys
              end

              private

              # used internally to set the columns from this objects initialize method
              def add_column column
                # assert that the provided dsl name is an array of Columns
                unless column.is_a? Column
                  raise ExpectedArrayOfColumnsError
                end

                # assert that the provided column exists within this unique_constraints table
                unless @table.has_column? column.name
                  raise ExpectedArrayOfColumnsError, "One or more columns do not exist in this unique_constraints table"
                end

                if @columns.key?(column.name)
                  raise(DuplicateColumnError, "Column #{column.name} already exists in unique_constraint, or is already included")
                end

                @columns[column.name] = column
              end
            end
          end
        end
      end
    end
  end
end
