# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                module PrimaryKey
                  def process_primary_key schema_name, table_name, configuration_primary_key, database_primary_key
                    configuration_primary_key_exists = configuration_primary_key && configuration_primary_key[:exists]
                    database_primary_key_exists = database_primary_key && database_primary_key[:exists]

                    # If the primary_key exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_primary_key_exists == true && database_primary_key_exists == false
                      # a migration to create the primary_key
                      primary_key = @database.configured_schema(schema_name).table(table_name).primary_key
                      @generator.add_primary_key primary_key

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif configuration_primary_key_exists == false && database_primary_key_exists == true
                      # a migration to create the primary_key
                      primary_key = @database.loaded_schema(schema_name).table(table_name).primary_key
                      @generator.remove_primary_key primary_key

                    # If the primary_key exists in both the configuration and database representations
                    elsif configuration_primary_key_exists == true && database_primary_key_exists == true
                      # If the definition (i.e. the column names) is different then we need to update the primary key.
                      if configuration_primary_key.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                        # recreate the primary_key
                        original_primary_key = @database.loaded_schema(schema_name).table(table_name).primary_key
                        updated_primary_key = @database.configured_schema(schema_name).table(table_name).primary_key
                        @generator.recreate_primary_key original_primary_key, updated_primary_key
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
