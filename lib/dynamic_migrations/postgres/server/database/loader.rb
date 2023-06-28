# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module Loader
          # returns a list of the schema names in this database
          def fetch_schema_names
            rows = connection.exec(<<-SQL)
              SELECT schema_name
                FROM information_schema.schemata;
            SQL
            schema_names = rows.map { |row| row["schema_name"] }
            schema_names.reject! { |schema_name| schema_name == "information_schema" }
            schema_names.reject! { |schema_name| schema_name == "public" }
            schema_names.reject! { |schema_name| schema_name.start_with? "pg_" }
            schema_names
          end

          # returns a list of the table names in the provided schema
          def fetch_table_names schema_name
            rows = connection.exec_params(<<-SQL, [schema_name.to_s])
                  SELECT table_name FROM information_schema.tables
                    WHERE table_schema = $1
            SQL
            rows.map { |row| row["table_name"] }
          end

          # returns a list of columns definitions for the provided table
          def fetch_columns schema_name, table_name
            rows = connection.exec_params(<<-SQL, [schema_name.to_s, table_name.to_s])
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
        end
      end
    end
  end
end
