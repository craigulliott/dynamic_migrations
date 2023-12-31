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

          # adds a new loaded schema for this database
          def add_loaded_schema schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            if has_loaded_schema? schema_name
              raise LoadedSchemaAlreadyExistsError, "Loaded schema #{schema_name} already exists"
            end
            included_target = self
            if included_target.is_a? Database
              new_schema = @loaded_schemas[schema_name] = Schema.new :database, included_target, schema_name
            else
              raise ModuleIncludedIntoUnexpectedTargetError, included_target
            end
            # sort the hash so that the schemas are in alphabetical order by name
            sorted_schemas = {}
            @loaded_schemas.keys.sort.each do |schema_name|
              sorted_schemas[schema_name] = @loaded_schemas[schema_name]
            end
            @loaded_schemas = sorted_schemas
            # return the new schema
            new_schema
          end

          # returns the loaded schema object for the provided schema name, and raises an
          # error if the schema does not exist
          def loaded_schema schema_name
            unless schema_name.is_a? Symbol
              raise ExpectedSymbolError, schema_name
            end
            unless has_loaded_schema? schema_name
              raise LoadedSchemaDoesNotExistError, "Loaded schema `#{schema_name}` does not exist"
            end
            @loaded_schemas[schema_name]
          end

          # returns true if this table has a loaded schema with the provided name, otherwise false
          def has_loaded_schema? schema_name
            raise ExpectedSymbolError, schema_name unless schema_name.is_a? Symbol
            @loaded_schemas.key? schema_name
          end

          # returns an array of this tables loaded schemas
          def loaded_schemas
            @loaded_schemas.values
          end

          # returns a hash of this tables loaded schemas, keyed by schema name
          def loaded_schemas_hash
            @loaded_schemas
          end
        end
      end
    end
  end
end
