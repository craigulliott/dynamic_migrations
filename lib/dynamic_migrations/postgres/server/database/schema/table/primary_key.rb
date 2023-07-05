# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a postgres table primary_key
            class PrimaryKey < Source
              INDEX_TYPES = [:btree, :gin]

              class ExpectedTableError < StandardError
              end

              class ExpectedArrayOfColumnsError < StandardError
              end

              class UnexpectedIndexTypeError < StandardError
              end

              class DuplicateColumnError < StandardError
              end

              attr_reader :table
              attr_reader :primary_key_name
              attr_reader :index_type

              # initialize a new object to represent a primary_key in a postgres table
              def initialize source, table, columns, primary_key_name, index_type: :btree
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

                raise ExpectedSymbolError, primary_key_name unless primary_key_name.is_a? Symbol
                @primary_key_name = primary_key_name

                raise UnexpectedIndexTypeError, index_type unless INDEX_TYPES.include?(index_type)
                @index_type = index_type
              end

              # return an array of this primary keys columns
              def columns
                @columns.values
              end

              private

              # used internally to set the columns from this objects initialize method
              def add_column column
                # assert that the provided dsl name is an array of Columns
                unless column.is_a? Column
                  raise ExpectedArrayOfColumnsError
                end

                # assert that the provided column exists within this primary keys table
                unless @table.has_column? column.column_name
                  raise ExpectedArrayOfColumnsError, "One or more columns do not exist in this primary keys table"
                end

                if @columns.key?(column.column_name)
                  raise(DuplicateColumnError, "Column #{column.column_name} already exists in primary_key, or is already included")
                end

                @columns[column.column_name] = column
              end
            end
          end
        end
      end
    end
  end
end
