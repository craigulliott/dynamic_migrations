# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module ConfiguredSchemas
          class ConfiguredSchemaAlreadyExistsError < StandardError
          end

          class ConfiguredSchemaDoesNotExistError < StandardError
          end

          def add_configured_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            if has_configured_schema? schema_name
              raise(ConfiguredSchemaAlreadyExistsError, "Configured schema #{schema_name} already exists")
            end
            @configured_schemas[schema_name] = Schema.new :configuration, self, schema_name
          end

          def configured_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            raise ConfiguredSchemaDoesNotExistError unless has_configured_schema? schema_name
            @configured_schemas[schema_name]
          end

          def has_configured_schema? schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            @configured_schemas.key? schema_name
          end

          def configured_schemas
            @configured_schemas.values
          end
        end
      end
    end
  end
end
