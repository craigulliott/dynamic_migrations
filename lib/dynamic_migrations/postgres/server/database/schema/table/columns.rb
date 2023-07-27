# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table < Source
            # This module has all the tables methods for working with columns
            module Columns
              class ColumnDoesNotExistError < StandardError
              end

              class DuplicateColumnError < StandardError
              end

              # returns the column object for the provided column name, and raises an
              # error if the column does not exist
              def column name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                raise ColumnDoesNotExistError unless has_column? name
                @columns[name]
              end

              # returns true if this table has a column with the provided name, otherwise false
              def has_column? name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @columns.key? name
              end

              # returns an array of this tables columns
              def columns
                @columns.values
              end

              def columns_hash
                @columns
              end

              # adds a new column to this table, and returns it
              def add_column name, data_type, **column_options
                if has_column? name
                  raise(DuplicateColumnError, "Column #{name} already exists")
                end
                included_target = self
                if included_target.is_a? Table
                  new_column = @columns[name] = Column.new source, included_target, name, data_type, **column_options
                else
                  raise ModuleIncludedIntoUnexpectedTargetError, included_target
                end
                # sort the hash so that the columns are in alphabetical order by name
                sorted_columns = {}
                @columns.keys.sort.each do |name|
                  sorted_columns[name] = @columns[name]
                end
                @columns = sorted_columns
                # return the new column
                new_column
              end
            end
          end
        end
      end
    end
  end
end
