# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema < Source
          module Tables
            class TableAlreadyExistsError < StandardError
            end

            class TableDoesNotExistError < StandardError
            end

            # create and add a new table from a provided table name
            def add_table table_name, description: nil
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              if has_table? table_name
                raise(TableAlreadyExistsError, "Table #{table_name} already exists")
              end
              included_target = self
              if included_target.is_a? Schema
                new_table = @tables[table_name] = Table.new source, included_target, table_name, description: description
              else
                raise ModuleIncludedIntoUnexpectedTargetError, included_target
              end
              # sort the hash so that the tables are in alphabetical order by name
              sorted_tables = {}
              @tables.keys.sort.each do |table_name|
                sorted_tables[table_name] = @tables[table_name]
              end
              @tables = sorted_tables
              # return the new table
              new_table
            end

            # return a table by its name, raises an error if the table does not exist
            def table table_name
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              raise TableDoesNotExistError unless has_table? table_name
              @tables[table_name]
            end

            # returns true/false representing if a table with the provided name exists
            def has_table? table_name
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              @tables.key? table_name
            end

            # returns an array of all tables in the schema
            def tables
              @tables.values
            end

            def tables_hash
              @tables
            end
          end
        end
      end
    end
  end
end
