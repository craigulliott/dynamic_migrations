# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                def process_tables schema_name, configuration_tables, database_tables
                  # process all the tables
                  log.debug "  Processing Tables"
                  table_names = (configuration_tables.keys + database_tables.keys).uniq
                  table_names.each do |table_name|
                    log.debug "  Processing Table #{table_name}"
                    process_table schema_name, table_name, configuration_tables[table_name] || {}, database_tables[table_name] || {}
                  end
                end

                def process_table schema_name, table_name, configuration_table, database_table
                  # If the table exists in the configuration but not in the database
                  # then we have to create it.
                  if configuration_table[:exists] == true && !database_table[:exists]
                    log.debug "  Table `#{table_name}` exists in configuration but not in the database"

                    # a migration to create the table
                    table = @database.configured_schema(schema_name).table(table_name)
                    @generator.create_table table

                    # we process everything else after we create the table, because the other
                    # database objects are dependent on the table
                    process_dependents schema_name, table_name, configuration_table, {}, skip_columns: true

                  # If the schema exists in the database but not in the configuration
                  # then we need to delete it.
                  elsif database_table[:exists] == true && !configuration_table[:exists]
                    log.debug "  Table `#{table_name}` exists in database but not in the configuration"

                    # we process everything else before we drop the table, because the other
                    # database objects are dependent on the table
                    process_dependents schema_name, table_name, {}, database_table

                    # a migration to remove the table
                    table = @database.loaded_schema(schema_name).table(table_name)
                    @generator.drop_table table

                  # If the table exists in both the configuration and database representations
                  # but the description is different then we need to update the description.
                  elsif configuration_table[:description][:matches] == false
                    log.debug "  Table `#{table_name}` exists in both configuration and the database"

                    table = @database.configured_schema(schema_name).table(table_name)
                    # if the description was removed
                    if configuration_table[:description].nil?
                      log.debug "    Table `#{table_name}` description exists in database but not in the configuration"
                      @generator.remove_table_comment table
                    else
                      log.debug "    Table `#{table_name}` description does not match"
                      @generator.set_table_comment table
                    end

                    # process everything else
                    process_dependents schema_name, table_name, configuration_table, database_table

                  else
                    log.debug "  Table `#{table_name}` exists in both configuration and the database"
                    # process everything else
                    process_dependents schema_name, table_name, configuration_table, database_table

                  end
                end

                def process_dependents schema_name, table_name, configuration_table, database_table, skip_columns: false
                  # we skip columns if we are processing the table for the first time, as they are processed within the table creation
                  unless skip_columns
                    process_columns schema_name, table_name, configuration_table[:columns] || {}, database_table[:columns] || {}
                  end
                  process_foreign_key_constraints schema_name, table_name, configuration_table[:foreign_key_constraints] || {}, database_table[:foreign_key_constraints] || {}
                  process_indexes schema_name, table_name, configuration_table[:indexes] || {}, database_table[:indexes] || {}
                  process_triggers schema_name, table_name, configuration_table[:triggers] || {}, database_table[:triggers] || {}
                  process_unique_constraints schema_name, table_name, configuration_table[:unique_constraints] || {}, database_table[:unique_constraints] || {}
                  process_validations schema_name, table_name, configuration_table[:validations] || {}, database_table[:validations] || {}
                  # Process the primary key. The primary key is singular (max of one per table)
                  process_primary_key schema_name, table_name, configuration_table[:primary_key], database_table[:primary_key]
                end
              end
            end
          end
        end
      end
    end
  end
end
