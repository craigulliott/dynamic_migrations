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
                    # process all the unique_constraints
                    unique_constraint_names = (configuration_unique_constraints.keys + database_unique_constraints.keys).uniq
                    unique_constraint_names.each do |unique_constraint_name|
                      process_unique_constraint schema_name, table_name, unique_constraint_name, configuration_unique_constraints[unique_constraint_name] || {}, database_unique_constraints[unique_constraint_name] || {}
                    end
                  end

                  def process_unique_constraint schema_name, table_name, unique_constraint_name, configuration_unique_constraint, database_unique_constraint
                    # If the unique_constraint exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_unique_constraint[:exists] == true && database_unique_constraint[:exists] == false
                      # a migration to create the unique_constraint
                      unique_constraint = @database.configured_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      @generator.add_unique_constraint unique_constraint

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif configuration_unique_constraint[:exists] == false && database_unique_constraint[:exists] == true
                      # a migration to create the unique_constraint
                      unique_constraint = @database.loaded_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      @generator.remove_unique_constraint unique_constraint

                    # If the unique_constraint exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_unique_constraint.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      # configuration_unique_constraint[:definition][:matches] == false
                      unique_constraint = @database.configured_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      @generator.change_unique_constraint unique_constraint
                      # does the description also need to be updated
                      if configuration_unique_constraint[:description][:matches] == false
                        # if the description was removed
                        if configuration_unique_constraint[:description].nil?
                          @generator.remove_unique_constraint_comment unique_constraint
                        else
                          @generator.set_unique_constraint_comment unique_constraint
                        end
                      end

                    # If the unique_constraint exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_unique_constraint[:description][:matches] == false
                      unique_constraint = @database.configured_schema(schema_name).table(table_name).unique_constraint(unique_constraint_name)
                      # if the description was removed
                      if configuration_unique_constraint[:description].nil?
                        @generator.remove_unique_constraint_comment unique_constraint
                      else
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
