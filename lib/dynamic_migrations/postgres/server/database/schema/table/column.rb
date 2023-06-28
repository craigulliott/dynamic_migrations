# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a single column within a postgres table
            class Column
              class ExpectedSymbolError < StandardError
              end

              class ExpectedTableError < StandardError
              end

              attr_reader :table
              attr_reader :column_name

              # initialize a new object to represent a column in a postgres table
              def initialize table, column_name, type, null: true, description: nil, default: nil
                raise ExpectedTableError, table unless table.is_a? Table
                raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
                @table = table
                @column_name = column_name
                @type = type
                @null = null
                @description = description
                @default = default
              end
            end
          end
        end
      end
    end
  end
end
