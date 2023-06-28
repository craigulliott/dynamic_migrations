# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module LoadedSchemas
          class LoadedSchemaAlreadyExistsError < StandardError
          end

          class LoadedSchemaDoesNotExistError < StandardError
          end

          def add_loaded_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            if has_loaded_schema? schema_name
              raise(LoadedSchemaAlreadyExistsError, "Loaded schema #{schema_name} already exists")
            end
            @loaded_schemas[schema_name] = Schema.new :database, self, schema_name
          end

          def loaded_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            raise LoadedSchemaDoesNotExistError unless has_loaded_schema? schema_name
            @loaded_schemas[schema_name]
          end

          def has_loaded_schema? schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            @loaded_schemas.key? schema_name
          end

          def loaded_schemas
            @loaded_schemas.values
          end
        end
      end
    end
  end
end
