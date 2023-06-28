# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          module ConfiguredTables
            class ConfiguredTableAlreadyExistsError < StandardError
            end

            def add_table_from_configuration table_name
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              if configured_table table_name
                raise(ConfiguredTableAlreadyExistsError, "Configured table #{table_name} already exists")
              end
              @configured_tables[table_name] = Table.new self, table_name
            end

            def configured_table table_name
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              @configured_tables[table_name]
            end

            def configured_tables
              @configured_tables.values
            end
          end
        end
      end
    end
  end
end
