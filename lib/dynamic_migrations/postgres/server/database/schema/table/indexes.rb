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
              def index name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                raise IndexDoesNotExistError unless has_index? name
                @indexes[name]
              end

              # returns true if this table has a index with the provided name, otherwise false
              def has_index? name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @indexes.key? name
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
              def add_index name, column_names, include_column_names: [], **index_options
                if has_index? name
                  raise(IndexAlreadyExistsError, "index #{name} already exists")
                end
                columns = column_names.map { |column_name| column column_name }
                include_columns = include_column_names.map { |column_name| column column_name }
                included_target = self
                if included_target.is_a? Table
                  new_index = @indexes[name] = Index.new source, included_target, columns, name, include_columns: include_columns, **index_options
                else
                  raise ModuleIncludedIntoUnexpectedTargetError, included_target
                end
                # sort the hash so that the indexes are in alphabetical order by name
                sorted_indexes = {}
                @indexes.keys.sort.each do |name|
                  sorted_indexes[name] = @indexes[name]
                end
                @indexes = sorted_indexes
                # return the new index
                new_index
              end
            end
          end
        end
      end
    end
  end
end
