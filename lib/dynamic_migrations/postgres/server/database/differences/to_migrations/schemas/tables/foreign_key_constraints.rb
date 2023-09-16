# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                module ForeignKeyConstraints
                  def process_foreign_key_constraints schema_name, table_name, configuration_foreign_key_constraints, database_foreign_key_constraints
                    # process all the foreign_key_constraints
                    foreign_key_constraint_names = (configuration_foreign_key_constraints.keys + database_foreign_key_constraints.keys).uniq
                    foreign_key_constraint_names.each do |foreign_key_constraint_name|
                      process_foreign_key_constraint schema_name, table_name, foreign_key_constraint_name, configuration_foreign_key_constraints[foreign_key_constraint_name] || {}, database_foreign_key_constraints[foreign_key_constraint_name] || {}
                    end
                  end

                  def process_foreign_key_constraint schema_name, table_name, foreign_key_constraint_name, configuration_foreign_key_constraint, database_foreign_key_constraint
                    # If the foreign_key_constraint exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_foreign_key_constraint[:exists] == true && !database_foreign_key_constraint[:exists]
                      # a migration to create the foreign_key_constraint
                      foreign_key_constraint = @database.configured_schema(schema_name).table(table_name).foreign_key_constraint(foreign_key_constraint_name)
                      @generator.add_foreign_key_constraint foreign_key_constraint

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif database_foreign_key_constraint[:exists] == true && !configuration_foreign_key_constraint[:exists]
                      # a migration to create the foreign_key_constraint
                      foreign_key_constraint = @database.loaded_schema(schema_name).table(table_name).foreign_key_constraint(foreign_key_constraint_name)
                      @generator.remove_foreign_key_constraint foreign_key_constraint

                    # If the foreign_key_constraint exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_foreign_key_constraint.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      # recreate the foreign_key_constraint
                      original_foreign_key_constraint = @database.loaded_schema(schema_name).table(table_name).foreign_key_constraint(foreign_key_constraint_name)
                      updated_foreign_key_constraint = @database.configured_schema(schema_name).table(table_name).foreign_key_constraint(foreign_key_constraint_name)
                      @generator.recreate_foreign_key_constraint original_foreign_key_constraint, updated_foreign_key_constraint
                      # does the description also need to be updated
                      if configuration_foreign_key_constraint[:description][:matches] == false
                        # if the description was removed
                        if configuration_foreign_key_constraint[:description].nil?
                          @generator.remove_foreign_key_constraint_comment updated_foreign_key_constraint
                        else
                          @generator.set_foreign_key_constraint_comment updated_foreign_key_constraint
                        end
                      end

                    # If the foreign_key_constraint exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_foreign_key_constraint[:description][:matches] == false
                      foreign_key_constraint = @database.configured_schema(schema_name).table(table_name).foreign_key_constraint(foreign_key_constraint_name)
                      # if the description was removed
                      if configuration_foreign_key_constraint[:description].nil?
                        @generator.remove_foreign_key_constraint_comment foreign_key_constraint
                      else
                        @generator.set_foreign_key_constraint_comment foreign_key_constraint
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
