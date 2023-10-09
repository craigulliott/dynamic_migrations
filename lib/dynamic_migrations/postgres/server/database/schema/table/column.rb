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

              class InvalidNameError < StandardError
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

                raise InvalidNameError, "Unexpected name `#{name}`. Name should be a Symbol" unless name.is_a? Symbol
                raise InvalidNameError, "The name `#{name}` is too long. Names must be less than 64 characters" unless name.length < 64
                @name = name

                raise ExpectedSymbolError, data_type unless data_type.is_a? Symbol
                @data_type = data_type

                @null = null

                unless default.nil?
                  raise ExpectedStringError, default unless default.is_a? String
                  @default = default
                end

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description.strip.freeze
                  @description = nil if description == ""
                end

                @interval_type = interval_type

                if enum
                  unless enum.is_a? Enum
                    raise UnexpectedEnumError, "#{enum} is not a valid enum"
                  end
                  if (array? && @data_type != :"#{enum.full_name}[]") || (!array? && @data_type != enum.full_name)
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

              # for arrays returns the column type without the array brackets, for non arrays
              # jsut returnms the column type
              def base_data_type
                array? ? @data_type[0..-3]&.to_sym : @data_type
              end
            end
          end
        end
      end
    end
  end
end
