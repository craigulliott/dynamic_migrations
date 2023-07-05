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

          # adds a new configured schema for this database
          def add_configured_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            if has_configured_schema? schema_name
              raise(ConfiguredSchemaAlreadyExistsError, "Configured schema #{schema_name} already exists")
            end
            included_target = self
            if included_target.is_a? Database
              @configured_schemas[schema_name] = Schema.new :configuration, included_target, schema_name
            else
              raise ModuleIncludedIntoUnexpectedTargetError, included_target
            end
          end

          # returns the configured schema object for the provided schema name, and raises an
          # error if the schema does not exist
          def configured_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            raise ConfiguredSchemaDoesNotExistError unless has_configured_schema? schema_name
            @configured_schemas[schema_name]
          end

          # returns true if this table has a configured schema with the provided name, otherwise false
          def has_configured_schema? schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            @configured_schemas.key? schema_name
          end

          # returns an array of this tables configured schemas
          def configured_schemas
            @configured_schemas.values
          end

          # returns a hash of this tables configured schemas, keyed by schema name
          def configured_schemas_hash
            @configured_schemas
          end
        end
      end
    end
  end
end
