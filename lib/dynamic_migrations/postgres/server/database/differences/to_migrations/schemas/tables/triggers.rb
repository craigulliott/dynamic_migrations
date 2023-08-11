# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                module Triggers
                  def process_triggers schema_name, table_name, configuration_triggers, database_triggers
                    # process all the triggers
                    trigger_names = (configuration_triggers.keys + database_triggers.keys).uniq
                    trigger_names.each do |trigger_name|
                      process_trigger schema_name, table_name, trigger_name, configuration_triggers[trigger_name] || {}, database_triggers[trigger_name] || {}
                    end
                  end

                  def process_trigger schema_name, table_name, trigger_name, configuration_trigger, database_trigger
                    # If the trigger exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_trigger[:exists] == true && database_trigger[:exists] == false
                      # a migration to create the trigger
                      trigger = @database.configured_schema(schema_name).table(table_name).trigger(trigger_name)
                      @generator.add_trigger trigger

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif configuration_trigger[:exists] == false && database_trigger[:exists] == true
                      # a migration to create the trigger
                      trigger = @database.loaded_schema(schema_name).table(table_name).trigger(trigger_name)
                      @generator.remove_trigger trigger

                    # If the trigger exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_trigger.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      # recreate the trigger
                      original_trigger = @database.loaded_schema(schema_name).table(table_name).trigger(trigger_name)
                      updated_trigger = @database.configured_schema(schema_name).table(table_name).trigger(trigger_name)
                      @generator.recreate_trigger original_trigger, updated_trigger
                      # does the description also need to be updated
                      if configuration_trigger[:description][:matches] == false
                        # if the description was removed
                        if configuration_trigger[:description].nil?
                          @generator.remove_trigger_comment trigger
                        else
                          @generator.set_trigger_comment trigger
                        end
                      end

                    # If the trigger exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_trigger[:description][:matches] == false
                      trigger = @database.configured_schema(schema_name).table(table_name).trigger(trigger_name)
                      # if the description was removed
                      if configuration_trigger[:description].nil?
                        @generator.remove_trigger_comment trigger
                      else
                        @generator.set_trigger_comment trigger
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
