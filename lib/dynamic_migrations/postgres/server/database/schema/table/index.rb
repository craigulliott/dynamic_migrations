# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a postgres table index
            class Index < Source
              INDEX_TYPES = [:btree, :hash, :gist, :gin, :bring, :spgist]
              ORDERS = [:asc, :desc]
              NULL_POSITIONS = [:first, :last]

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

              class InvalidNameError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :unique
              attr_reader :where
              attr_reader :type
              attr_reader :order
              attr_reader :nulls_position
              attr_reader :description

              # initialize a new object to represent a index in a postgres table
              def initialize source, table, columns, name, description: nil, unique: false, where: nil, type: :btree, include_columns: [], order: :asc, nulls_position: :last
                super source
                raise ExpectedTableError, table unless table.is_a? Table
                @table = table
                @columns = {}
                @include_columns = {}

                # assert that the provided columns is an array
                unless columns.is_a?(Array) && columns.count > 0
                  raise ExpectedArrayOfColumnsError
                end

                columns.each do |column|
                  add_column column
                end

                raise InvalidNameError, "Unexpected name `#{name}`. Name should be a Symbol" unless name.is_a? Symbol
                raise InvalidNameError, "The name `#{name}` is too long. Names must be less than 64 characters" unless name.length < 64
                @name = name

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description.strip.freeze
                  @description = nil if description == ""
                end

                raise ExpectedBooleanError, unique unless [true, false].include?(unique)
                @unique = unique

                unless where.nil?
                  raise ExpectedStringError, where unless where.is_a? String
                  @where = where.freeze
                end

                raise UnexpectedIndexTypeError, type unless INDEX_TYPES.include?(type)
                @type = type

                # assert that the include_columns is an array (it's optional, so can be an empty array)
                unless include_columns.is_a?(Array)
                  raise ExpectedArrayOfColumnsError
                end

                include_columns.each do |include_column|
                  add_column include_column, is_include_column: true
                end

                raise UnexpectedOrderError, order unless ORDERS.include?(order)
                @order = order

                raise UnexpectedNullsPositionError, nulls_position unless NULL_POSITIONS.include?(nulls_position)
                @nulls_position = nulls_position
              end

              # return true if this has a description, otherwise false
              def has_description?
                !@description.nil?
              end

              # return an array of this indexes columns
              def columns
                @columns.values
              end

              def column_names
                @columns.keys
              end

              # return an array of this indexes include_columns
              def include_columns
                @include_columns.values
              end

              def include_column_names
                @include_columns.keys
              end

              def differences_descriptions other_index
                method_differences_descriptions other_index, [
                  :column_names,
                  :unique,
                  :where,
                  :type,
                  :order,
                  :nulls_position
                ]
              end

              private

              # used internally to set the columns from this objects initialize method
              def add_column column, is_include_column: false
                # assert that the provided dsl name is an array of Columns
                unless column.is_a? Column
                  raise ExpectedArrayOfColumnsError
                end

                # assert that the provided column exists within this indexes table
                unless @table.has_column? column.name
                  raise ExpectedArrayOfColumnsError, "One or more columns do not exist in this indexes table"
                end

                if @columns.key?(column.name) || @include_columns.key?(column.name)
                  raise(DuplicateColumnError, "Column #{column.name} already exists in index, or is already included")
                end

                if is_include_column
                  @include_columns[column.name] = column
                else
                  @columns[column.name] = column
                end
              end
            end
          end
        end
      end
    end
  end
end
