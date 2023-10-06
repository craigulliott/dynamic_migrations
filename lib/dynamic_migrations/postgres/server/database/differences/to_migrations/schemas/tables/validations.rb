# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                module Validations
                  def process_validations schema_name, table_name, configuration_validations, database_validations
                    # process all the validations
                    log.info "    Processing Validations..."
                    validation_names = (configuration_validations.keys + database_validations.keys).uniq
                    validation_names.each do |validation_name|
                      log.info "    Processing Validation #{validation_name}..."
                      process_validation schema_name, table_name, validation_name, configuration_validations[validation_name] || {}, database_validations[validation_name] || {}
                    end
                  end

                  def process_validation schema_name, table_name, validation_name, configuration_validation, database_validation
                    # If the validation exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_validation[:exists] == true && !database_validation[:exists]
                      log.info "    Validation `#{validation_name}` exists in configuration but not in the database"

                      # a migration to create the validation
                      validation = @database.configured_schema(schema_name).table(table_name).validation(validation_name)
                      @generator.add_validation validation

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif database_validation[:exists] == true && !configuration_validation[:exists]
                      log.info "    Validation `#{validation_name}` exists in database but not in the configuration"

                      # a migration to create the validation
                      validation = @database.loaded_schema(schema_name).table(table_name).validation(validation_name)
                      @generator.remove_validation validation

                    # If the validation exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_validation.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      log.info "    Validation `#{validation_name}` exists in both configuration and the database"

                      log.info "      Validation `#{validation_name}` is different"
                      # recreate the validation
                      original_validation = @database.loaded_schema(schema_name).table(table_name).validation(validation_name)
                      updated_validation = @database.configured_schema(schema_name).table(table_name).validation(validation_name)
                      @generator.recreate_validation original_validation, updated_validation
                      # does the description also need to be updated
                      if configuration_validation[:description][:matches] == false
                        # if the description was removed
                        if configuration_validation[:description].nil?
                          log.info "      Validation `#{validation_name}` description exists in database but not in the configuration"
                          @generator.remove_validation_comment updated_validation
                        else
                          log.info "      Validation `#{validation_name}` does not match"
                          @generator.set_validation_comment updated_validation
                        end
                      end

                    # If the validation exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_validation[:description][:matches] == false
                      log.info "    Validation `#{validation_name}` exists in both configuration and the database"

                      validation = @database.configured_schema(schema_name).table(table_name).validation(validation_name)
                      # if the description was removed
                      if configuration_validation[:description].nil?
                        log.info "      Validation `#{validation_name}` description exists in database but not in the configuration"
                        @generator.remove_validation_comment validation
                      else
                        log.info "      Validation `#{validation_name}` does not match"
                        @generator.set_validation_comment validation
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
