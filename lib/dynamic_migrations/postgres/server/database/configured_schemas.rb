# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module ConfiguredSchemas
          class ConfiguredSchemaAlreadyExistsError < StandardError
          end

          def add_schema_from_configuration schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            if configured_schema schema_name
              raise(ConfiguredSchemaAlreadyExistsError, "Configured schema #{schema_name} already exists")
            end
            @configured_schemas[schema_name] = Schema.new self, schema_name
          end

          def configured_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            @configured_schemas[schema_name]
          end

          def configured_schemas
            @configured_schemas.values
          end
        end
      end
    end
  end
end
