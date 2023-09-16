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

              class UnexpectedEnumError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :data_type
              attr_reader :description
              attr_reader :null
              attr_reader :default
              attr_reader :interval_type
              attr_reader :enum

              # initialize a new object to represent a column in a postgres table
              def initialize source, table, name, data_type, null: true, default: nil, description: nil, interval_type: nil, enum: nil
                super source
                raise ExpectedTableError, table unless table.is_a? Table
                @table = table

                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @name = name

                raise ExpectedSymbolError, data_type unless data_type.is_a? Symbol
                @data_type = data_type

                @null = null
                @default = default

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description.strip
                  @description = nil if description == ""
                end

                @interval_type = interval_type

                if enum
                  unless enum.is_a? Enum
                    raise UnexpectedEnumError, "#{enum} is not a valid enum"
                  end
                  unless @data_type == enum.full_name || @data_type == "#{enum.full_name}[]"
                    raise UnexpectedEnumError, "enum `#{enum.full_name}` does not match this column's data type `#{@data_type}`"
                  end
                  @enum = enum
                  # associate this column with the enum (so they are aware of each other)
                  enum.add_column self

                end
              end

              # return true if this column has a description, otherwise false
              def has_description?
                !@description.nil?
              end

              def array?
                @data_type.end_with? "[]"
              end

              def enum?
                !@enum.nil?
              end

              # sometimes this system makes temporary tables in order to fetch the normalized
              # version of constraint check clauses, function definitions or trigger action conditions
              # because certain data types might not yet exist, we need to use alternative types
              def temp_table_data_type
                if enum
                  :text
                elsif @data_type == :citext || @data_type == :"citext[]"
                  :text
                else
                  @data_type
                end
              end
            end
          end
        end
      end
    end
  end
end
