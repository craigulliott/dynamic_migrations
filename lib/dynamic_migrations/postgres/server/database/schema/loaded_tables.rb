# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          module LoadedTables
            class LoadedTableAlreadyExistsError < StandardError
            end

            def add_table_from_database table_name
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              if loaded_table table_name
                raise(LoadedTableAlreadyExistsError, "Loaded table #{table_name} already exists")
              end
              @loaded_tables[table_name] = Table.new self, table_name
            end

            def loaded_table table_name
              raise ExpectedSymbolError, table_name unless table_name.is_a? Symbol
              @loaded_tables[table_name]
            end

            def loaded_tables
              @loaded_tables.values
            end

            # returns a list of the table names in this schema
            def fetch_table_names
              rows = database.connection.exec_params(<<-SQL, [schema_name])
                SELECT table_name FROM information_schema.tables
                  WHERE table_schema = $1
              SQL
              rows.map { |row| row["table_name"] }
            end

            # builds a table object for each table in this schema
            def load_tables
              fetch_table_names.each do |table_name|
                add_table_from_database table_name.to_sym
              end
            end
          end
        end
      end
    end
  end
end
