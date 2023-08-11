# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a postgres table primary_key
            class PrimaryKey < Source
              class ExpectedTableError < StandardError
              end

              class ExpectedArrayOfColumnsError < StandardError
              end

              class UnexpectedIndexTypeError < StandardError
              end

              class DuplicateColumnError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :description

              # initialize a new object to represent a primary_key in a postgres table
              def initialize source, table, columns, name, description: nil
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

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description
                end
              end

              # return true if this has a description, otherwise false
              def has_description?
                !@description.nil?
              end

              # return an array of this primary keys columns
              def columns
                @columns.values
              end

              def column_names
                @columns.keys
              end

              def differences_descriptions other_primary_key
                method_differences_descriptions other_primary_key, [
                  :column_names
                ]
              end

              private

              # used internally to set the columns from this objects initialize method
              def add_column column
                # assert that the provided dsl name is an array of Columns
                unless column.is_a? Column
                  raise ExpectedArrayOfColumnsError
                end

                # assert that the provided column exists within this primary keys table
                unless @table.has_column? column.name
                  raise ExpectedArrayOfColumnsError, "One or more columns do not exist in this primary keys table"
                end

                if @columns.key?(column.name)
                  raise(DuplicateColumnError, "Column #{column.name} already exists in primary_key, or is already included")
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
