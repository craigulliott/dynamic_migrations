# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Functions
                def process_functions schema_name, configuration_functions, database_functions
                  # process all the functions
                  log.debug "  Processing Functions"
                  function_names = (configuration_functions.keys + database_functions.keys).uniq
                  function_names.each do |function_name|
                    log.debug "  Processing Function #{function_name}"
                    process_function schema_name, function_name, configuration_functions[function_name] || {}, database_functions[function_name] || {}
                  end
                end

                def process_function schema_name, function_name, configuration_function, database_function
                  # If the function exists in the configuration but not in the database
                  # then we have to create it.
                  if configuration_function[:exists] == true && !database_function[:exists]
                    log.debug "  Function `#{function_name}` exists in configuration but not in the database"

                    # a migration to create the function
                    function = @database.configured_schema(schema_name).function(function_name)
                    @generator.create_function function

                  # If the schema exists in the database but not in the configuration
                  # then we need to delete it.
                  elsif database_function[:exists] == true && !configuration_function[:exists]
                    log.debug "  Function `#{function_name}` exists in database but not in the configuration"

                    # a migration to create the function
                    function = @database.loaded_schema(schema_name).function(function_name)
                    @generator.drop_function function

                  # If the function exists in both the configuration and database representations
                  # but the definition is different then we need to update the definition.
                  elsif configuration_function[:normalized_definition][:matches] == false
                    log.debug "  Function `#{function_name}` exists in both configuration and the database"

                    log.debug "    Function `#{function_name}` definition is different"
                    function = @database.configured_schema(schema_name).function(function_name)
                    @generator.update_function function
                    # does the description also need to be updated
                    if configuration_function[:description][:matches] == false
                      # if the description was removed
                      if configuration_function[:description].nil?
                        log.debug "    Function `#{function_name}` description exists in database but not in the configuration"
                        @generator.remove_function_comment function
                      else
                        log.debug "    Function `#{function_name}` description does not match"
                        @generator.set_function_comment function
                      end
                    end

                  # If the function exists in both the configuration and database representations
                  # but the description is different then we need to update the description.
                  elsif configuration_function[:description][:matches] == false
                    log.debug "  Function `#{function_name}` exists in both configuration and the database"

                    function = @database.configured_schema(schema_name).function(function_name)
                    # if the description was removed
                    if configuration_function[:description].nil?
                      log.debug "    Function `#{function_name}` description exists in database but not in the configuration"
                      @generator.remove_function_comment function
                    else
                      log.debug "    Function `#{function_name}` description does not match"
                      @generator.set_function_comment function
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
