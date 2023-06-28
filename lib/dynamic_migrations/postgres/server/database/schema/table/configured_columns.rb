# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            module ConfiguredColumns
              class ConfiguredColumnAlreadyExistsError < StandardError
              end

              def add_column_from_configuration column_name, type
                raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
                if configured_column column_name
                  raise(ConfiguredColumnAlreadyExistsError, "Configured column #{column_name} already exists")
                end
                @configured_columns[column_name] = Column.new self, column_name, type
              end

              def configured_column column_name
                raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
                @configured_columns[column_name]
              end

              def configured_columns
                @configured_columns.values
              end
            end
          end
        end
      end
    end
  end
end
