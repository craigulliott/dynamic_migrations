# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              def process_schema schema_name, configuration_schema, database_schema
                # if the schema exists in the configuration but not in the database
                # then we have to create it
                if configuration_schema[:exists] == true && !database_schema[:exists]
                  log.info "Schema `#{schema_name}` exists in configuration but not in the database"

                  # a migration to create the schema
                  schema = @database.configured_schema schema_name
                  @generator.create_schema schema

                  # we process the tables and functions after we create the schema
                  # otherwise the schemas objects will not be able to be created
                  process_functions schema_name, configuration_schema[:functions], {}
                  process_enums schema_name, configuration_schema[:enums], {}
                  process_tables schema_name, configuration_schema[:tables], {}

                # if the schema exists in the database but not in the configuration
                # then we need to delete it
                elsif database_schema[:exists] == true && !configuration_schema[:exists]
                  log.info "Schema `#{schema_name}` exists in database but not in the configuration"
                  # we process the tables and functions before we drop the schema
                  # as this will drop any dependencies on the schema
                  process_functions schema_name, {}, database_schema[:functions]
                  process_enums schema_name, {}, database_schema[:enums]
                  process_tables schema_name, {}, database_schema[:tables]

                  # a migration to drop the schema
                  schema = @database.loaded_schema schema_name
                  @generator.drop_schema schema

                # if the schema exists in both the configuration and database representations
                # then we just need to process the tables and functions
                else
                  log.info "Schema `#{schema_name}` exists in both configuration and the database"
                  process_functions schema_name, configuration_schema[:functions], database_schema[:functions]
                  process_enums schema_name, configuration_schema[:enums], database_schema[:enums]
                  process_tables schema_name, configuration_schema[:tables], database_schema[:tables]
                end
              end
            end
          end
        end
      end
    end
  end
end
