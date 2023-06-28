# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            module LoadedColumns
              class LoadedColumnAlreadyExistsError < StandardError
              end

              def add_column_from_database column_name, type
                raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
                if loaded_column column_name
                  raise(LoadedColumnAlreadyExistsError, "Loaded column #{column_name} already exists")
                end
                @loaded_columns[column_name] = Column.new self, column_name, type
              end

              def loaded_column column_name
                raise ExpectedSymbolError, column_name unless column_name.is_a? Symbol
                @loaded_columns[column_name]
              end

              def loaded_columns
                @loaded_columns.values
              end

              # returns a list of the table names in this schema
              def fetch_columns
                rows = schema.database.connection.exec_params(<<-SQL, [schema.schema_name.to_s, table_name.to_s])
                  SELECT column_name, is_nullable, data_type, character_octet_length, column_default, numeric_precision, numeric_precision_radix, numeric_scale, udt_schema, udt_name
                    FROM information_schema.columns
                  WHERE table_schema = $1
                    AND table_name = $2;
                SQL
                rows.map do |row|
                  {
                    column_name: row["column_name"].to_sym,
                    type: row["data_type"].to_sym
                  }
                end
              end

              # builds a table object for each table in this schema
              def load_columns
                fetch_columns.each do |row|
                  add_column_from_database row[:column_name], row[:type]
                end
              end
            end
          end
        end
      end
    end
  end
end
