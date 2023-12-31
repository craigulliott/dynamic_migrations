# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                module UniqueConstraints
                  def process_unique_constraints schema_name, table_name, configuration_unique_constraints, database_unique_constraints
                    log.debug "    Processing Unique Constraints"
                    # process all the unique_constraints
                    unique_constraint_names = (configuration_unique_constraints.keys + database_unique_constraints.keys).uniq
                    unique_constraint_names.each do |unique_constraint_name|
                      log.debug "    Processing Unique Constraint #{unique_constraint_name}"
                      process_unique_constraint schema_name, table_name, unique_constraint_name, configuration_unique_constraints[unique_constraint_name] || {}, database_unique_constraints[unique_constraint_name] || {}
                    end
                  end

                  def process_unique_constraint schema_name, table_name, unique_constraint_name, configuration_unique_constraint, database_unique_constraint
                    # If the unique_constraint exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_unique_constraint[:exists] == true && !database_unique_constraint[:exists]
                      log.debug "    Unique Constraint `#{unique_constraint_name}` exists in configuration but not in the database"

                      # a migration to create the unique_constraint
                      unique_constraint = @database.configured_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      @generator.add_unique_constraint unique_constraint

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif database_unique_constraint[:exists] == true && !configuration_unique_constraint[:exists]
                      log.debug "    Unique Constraint `#{unique_constraint_name}` exists in database but not in the configuration"

                      # a migration to create the unique_constraint
                      unique_constraint = @database.loaded_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      @generator.remove_unique_constraint unique_constraint

                    # If the unique_constraint exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_unique_constraint.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      log.debug "    Unique Constraint `#{unique_constraint_name}` exists in both configuration and the database"

                      log.debug "      Unique Constraint `#{unique_constraint_name}` is different"
                      # recreate the unique_constraint
                      original_unique_constraint = @database.loaded_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      updated_unique_constraint = @database.configured_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      @generator.recreate_unique_constraint original_unique_constraint, updated_unique_constraint
                      # does the description also need to be updated
                      if configuration_unique_constraint[:description][:matches] == false
                        # if the description was removed
                        if configuration_unique_constraint[:description].nil?
                          log.debug "      Unique Constraint `#{unique_constraint_name}` description exists in database but not in the configuration"
                          @generator.remove_unique_constraint_comment updated_unique_constraint
                        else
                          log.debug "      Unique Constraint `#{unique_constraint_name}` description does not match"
                          @generator.set_unique_constraint_comment updated_unique_constraint
                        end
                      end

                    # If the unique_constraint exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_unique_constraint[:description][:matches] == false
                      log.debug "    Unique Constraint `#{unique_constraint_name}` exists in both configuration and the database"

                      unique_constraint = @database.configured_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      # if the description was removed
                      if configuration_unique_constraint[:description].nil?
                        log.debug "      Unique Constraint `#{unique_constraint_name}` description exists in database but not in the configuration"
                        @generator.remove_unique_constraint_comment unique_constraint
                      else
                        log.debug "      Unique Constraint `#{unique_constraint_name}` description does not match"
                        @generator.set_unique_constraint_comment unique_constraint
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
