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
                    validation_names = (configuration_validations.keys + database_validations.keys).uniq
                    validation_names.each do |validation_name|
                      process_validation schema_name, table_name, validation_name, configuration_validations[validation_name] || {}, database_validations[validation_name] || {}
                    end
                  end

                  def process_validation schema_name, table_name, validation_name, configuration_validation, database_validation
                    # If the validation exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_validation[:exists] == true && database_validation[:exists] == false
                      # a migration to create the validation
                      validation = @database.configured_schema(schema_name).table(table_name).validation(validation_name)
                      @generator.add_validation validation

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif configuration_validation[:exists] == false && database_validation[:exists] == true
                      # a migration to create the validation
                      validation = @database.loaded_schema(schema_name).table(table_name).validation(validation_name)
                      @generator.remove_validation validation

                    # If the validation exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_validation.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      # configuration_validation[:definition][:matches] == false
                      validation = @database.configured_schema(schema_name).table(table_name).validation(validation_name)
                      # update the validation
                      @generator.change_validation validation
                      # does the description also need to be updated
                      if configuration_validation[:description][:matches] == false
                        # if the description was removed
                        if configuration_validation[:description].nil?
                          @generator.remove_validation_comment validation
                        else
                          @generator.set_validation_comment validation
                        end
                      end

                    # If the validation exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_validation[:description][:matches] == false
                      validation = @database.configured_schema(schema_name).table(table_name).validation(validation_name)
                      # if the description was removed
                      if configuration_validation[:description].nil?
                        @generator.remove_validation_comment validation
                      else
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
