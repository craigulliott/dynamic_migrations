# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a single column within a postgres table
            class Column < Source
              class ExpectedTableError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :data_type
              attr_reader :description
              attr_reader :null
              attr_reader :default
              attr_reader :interval_type

              # initialize a new object to represent a column in a postgres table
              def initialize source, table, name, data_type, null: true, default: nil, description: nil, interval_type: nil
                super source
                raise ExpectedTableError, table unless table.is_a? Table
                @table = table

                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @name = name

                @data_type = data_type
                @null = null
                @default = default

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description.strip
                  @description = nil if description == ""
                end

                @interval_type = interval_type
              end

              # return true if this column has a description, otherwise false
              def has_description?
                !@description.nil?
              end

              def array?
                @data_type.end_with? "[]"
              end
            end
          end
        end
      end
    end
  end
end
