# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module LoadedSchemas
          class LoadedSchemaAlreadyExistsError < StandardError
          end

          def add_schema_from_database schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            if loaded_schema schema_name
              raise(LoadedSchemaAlreadyExistsError, "Loaded schema #{schema_name} already exists")
            end
            @loaded_schemas[schema_name] = Schema.new self, schema_name
          end

          def loaded_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            @loaded_schemas[schema_name]
          end

          def loaded_schemas
            @loaded_schemas.values
          end

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

          # builds a schema object for each schema in this database
          def load_schemas
            fetch_schema_names.each do |schema_name|
              add_schema_from_database schema_name.to_sym
            end
          end
        end
      end
    end
  end
end
