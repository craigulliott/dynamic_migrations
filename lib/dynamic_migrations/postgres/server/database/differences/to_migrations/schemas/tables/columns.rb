# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                module Columns
                  def process_columns schema_name, table_name, configuration_columns, database_columns
                    # process all the columns
                    log.debug "    Processing Columns"
                    column_names = (configuration_columns.keys + database_columns.keys).uniq
                    column_names.each do |column_name|
                      log.debug "    Processing Column #{column_name}"
                      process_column schema_name, table_name, column_name, configuration_columns[column_name] || {}, database_columns[column_name] || {}
                    end
                  end

                  def process_column schema_name, table_name, column_name, configuration_column, database_column
                    # If the column exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_column[:exists] == true && !database_column[:exists]
                      log.debug "    Column `#{column_name}` exists in configuration but not in the database"

                      # a migration to create the column
                      column = @database.configured_schema(schema_name).table(table_name).column(column_name)
                      @generator.add_column column

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif database_column[:exists] == true && !configuration_column[:exists]
                      log.debug "    Column `#{column_name}` exists in database but not in the configuration"

                      # a migration to create the column
                      column = @database.loaded_schema(schema_name).table(table_name).column(column_name)
                      @generator.remove_column column

                    # If the column exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_column.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      log.debug "    Column `#{column_name}` exists in both configuration and the database"

                      log.debug "      Column `#{column_name}` is different"
                      # update the column
                      column = @database.configured_schema(schema_name).table(table_name).column(column_name)
                      @generator.change_column column
                      # does the description also need to be updated
                      if configuration_column[:description][:matches] == false
                        # if the description was removed
                        if configuration_column[:description].nil?
                          log.debug "      Column `#{column_name}` description exists in database but not in the configuration"
                          @generator.remove_column_comment column
                        else
                          log.debug "      Column `#{column_name}` description does not match"
                          @generator.set_column_comment column
                        end
                      end

                    # If the column exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_column[:description][:matches] == false
                      log.debug "    Column `#{column_name}` exists in both configuration and the database"

                      column = @database.configured_schema(schema_name).table(table_name).column(column_name)
                      # if the description was removed
                      if configuration_column[:description].nil?
                        log.debug "      Column `#{column_name}` description exists in database but not in the configuration"
                        @generator.remove_column_comment column
                      else
                        log.debug "      Column `#{column_name}` description does not match"
                        @generator.set_column_comment column
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
