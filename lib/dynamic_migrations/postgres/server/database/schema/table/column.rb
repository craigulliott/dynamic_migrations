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
              attr_reader :column_name
              attr_reader :description
              attr_reader :null
              attr_reader :default
              attr_reader :data_type
              attr_reader :character_maximum_length
              attr_reader :character_octet_length
              attr_reader :numeric_precision
              attr_reader :numeric_precision_radix
              attr_reader :numeric_scale
              attr_reader :datetime_precision
              attr_reader :interval_type
              attr_reader :udt_schema
              attr_reader :udt_name
              attr_reader :updatable

              # initialize a new object to represent a column in a postgres table
              def initialize source, table, column_name, data_type, null: true, default: nil, description: nil, character_maximum_length: nil, character_octet_length: nil, numeric_precision: nil, numeric_precision_radix: nil, numeric_scale: nil, datetime_precision: nil, interval_type: nil, udt_schema: nil, udt_name: nil, updatable: true
                super source
                raise ExpectedTableError, table unless table.is_a? Table
                @table = table

                raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
                @column_name = column_name

                @data_type = data_type

                @null = null

                @default = default

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description
                end

                DataTypes.validate_column_properties!(data_type,
                  character_maximum_length: character_maximum_length,
                  character_octet_length: character_octet_length,
                  numeric_precision: numeric_precision,
                  numeric_precision_radix: numeric_precision_radix,
                  numeric_scale: numeric_scale,
                  datetime_precision: datetime_precision,
                  interval_type: interval_type,
                  udt_schema: udt_schema,
                  udt_name: udt_name)

                @character_maximum_length = character_maximum_length
                @character_octet_length = character_octet_length
                @numeric_precision = numeric_precision
                @numeric_precision_radix = numeric_precision_radix
                @numeric_scale = numeric_scale
                @datetime_precision = datetime_precision
                @interval_type = interval_type
                @udt_schema = udt_schema
                @udt_name = udt_name
                @updatable = updatable
              end

              # return true if this column has a description, otherwise false
              def has_description?
                !@description.nil?
              end
            end
          end
        end
      end
    end
  end
end
