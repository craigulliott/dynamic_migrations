# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a postgres table validation
            class Validation < Source
              class ExpectedTableError < StandardError
              end

              class ExpectedArrayOfColumnsError < StandardError
              end

              attr_reader :table
              attr_reader :validation_name
              attr_reader :check_clause

              # initialize a new object to represent a validation in a postgres table
              def initialize source, table, columns, validation_name, check_clause
                super source
                raise ExpectedTableError, table unless table.is_a? Table
                @table = table

                # assert that the provided columns is an array
                unless columns.is_a?(Array) && columns.count > 0
                  raise ExpectedArrayOfColumnsError
                end

                @columns = {}
                columns.each do |column|
                  add_column column
                end

                raise ExpectedSymbolError, validation_name unless validation_name.is_a? Symbol
                @validation_name = validation_name

                raise ExpectedStringError, check_clause unless check_clause.is_a? String
                @check_clause = check_clause
              end

              # return an array of this validations columns
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

                # assert that the provided column exists within this validations table
                unless @table.has_column? column.column_name
                  raise ExpectedArrayOfColumnsError, "One or more columns do not exist in this validations table"
                end

                if @columns.key? column.column_name
                  raise(ColumnAlreadyExistsError, "Column #{column.column_name} already exists")
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
