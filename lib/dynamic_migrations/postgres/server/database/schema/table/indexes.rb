# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table < Source
            # This module has all the tables methods for working with indexes
            module Indexes
              class IndexDoesNotExistError < StandardError
              end

              class IndexAlreadyExistsError < StandardError
              end

              # returns the index object for the provided index name, and raises an
              # error if the index does not exist
              def index index_name
                raise ExpectedSymbolError, index_name unless index_name.is_a? Symbol
                raise IndexDoesNotExistError unless has_index? index_name
                @indexes[index_name]
              end

              # returns true if this table has a index with the provided name, otherwise false
              def has_index? index_name
                raise ExpectedSymbolError, index_name unless index_name.is_a? Symbol
                @indexes.key? index_name
              end

              # returns an array of this tables indexes
              def indexes
                @indexes.values
              end

              def indexes_hash
                @indexes
              end

              # adds a new index to this table, and returns it
              # include_column_names in broken out from index_options, because it is converted from an
              # array of column names into an array of columns, and then recombined with the other
              # options which are sent to the index initialize method
              def add_index index_name, column_names, include_column_names: [], **index_options
                if has_index? index_name
                  raise(IndexAlreadyExistsError, "index #{index_name} already exists")
                end
                columns = column_names.map { |column_name| column column_name }
                include_columns = include_column_names.map { |column_name| column column_name }
                @indexes[index_name] = Index.new source, self, columns, index_name, include_columns: include_columns, **index_options
              end
            end
          end
        end
      end
    end
  end
end
