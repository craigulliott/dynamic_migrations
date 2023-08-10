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
                  def process_primary_key schema_name, table_name, primary_key_name, configuration_primary_key, database_primary_key
                    # If the primary_key exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_primary_key[:exists] == true && database_primary_key[:exists] == false
                      # a migration to create the primary_key
                      primary_key = @database.configured_schema(schema_name).table(table_name).primary_key(primary_key_name)
                      @generator.add_primary_key primary_key

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif configuration_primary_key[:exists] == false && database_primary_key[:exists] == true
                      # a migration to create the primary_key
                      primary_key = @database.loaded_schema(schema_name).table(table_name).primary_key(primary_key_name)
                      @generator.remove_primary_key primary_key

                    # If the primary_key exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_primary_key.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      # configuration_primary_key[:definition][:matches] == false
                      primary_key = @database.configured_schema(schema_name).table(table_name).primary_key(primary_key_name)
                      @generator.change_primary_key primary_key
                      # does the description also need to be updated
                      if configuration_primary_key[:description][:matches] == false
                        # if the description was removed
                        if configuration_primary_key[:description].nil?
                          @generator.remove_primary_key_comment primary_key
                        else
                          @generator.set_primary_key_comment primary_key
                        end
                      end

                    # If the primary_key exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_primary_key[:description][:matches] == false
                      primary_key = @database.configured_schema(schema_name).table(table_name).primary_key(primary_key_name)
                      # if the description was removed
                      if configuration_primary_key[:description].nil?
                        @generator.remove_primary_key_comment primary_key
                      else
                        @generator.set_primary_key_comment primary_key
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
