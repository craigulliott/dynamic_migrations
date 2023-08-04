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

              class DuplicateColumnError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :check_clause
              attr_reader :deferrable
              attr_reader :initially_deferred
              attr_reader :description

              # initialize a new object to represent a validation in a postgres table
              def initialize source, table, columns, name, check_clause, description: nil, deferrable: false, initially_deferred: false
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

                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @name = name

                raise ExpectedStringError, check_clause unless check_clause.is_a? String
                @check_clause = check_clause

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description
                end

                raise ExpectedBooleanError, deferrable unless [true, false].include?(deferrable)
                @deferrable = deferrable

                raise ExpectedBooleanError, initially_deferred unless [true, false].include?(initially_deferred)
                @initially_deferred = initially_deferred
              end

              # return true if this has a description, otherwise false
              def has_description?
                !@description.nil?
              end

              # return an array of this validations columns
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

                # assert that the provided column exists within this validations table
                unless @table.has_column? column.name
                  raise ExpectedArrayOfColumnsError, "One or more columns do not exist in this validations table"
                end

                if @columns.key? column.name
                  raise(DuplicateColumnError, "Column #{column.name} already exists")
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
