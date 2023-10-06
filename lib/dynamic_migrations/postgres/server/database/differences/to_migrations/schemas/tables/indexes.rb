# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                module Indexes
                  def process_indexes schema_name, table_name, configuration_indexes, database_indexes
                    # process all the indexes
                    log.info "    Processing Indexes..."
                    index_names = (configuration_indexes.keys + database_indexes.keys).uniq
                    index_names.each do |index_name|
                      log.info "    Processing Index #{index_name}..."
                      process_index schema_name, table_name, index_name, configuration_indexes[index_name] || {}, database_indexes[index_name] || {}
                    end
                  end

                  def process_index schema_name, table_name, index_name, configuration_index, database_index
                    # If the index exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_index[:exists] == true && !database_index[:exists]
                      log.info "    Index `#{index_name}` exists in configuration but not in the database"

                      # a migration to create the index
                      index = @database.configured_schema(schema_name).table(table_name).index(index_name)
                      @generator.add_index index

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif database_index[:exists] == true && !configuration_index[:exists]
                      log.info "    Index `#{index_name}` exists in database but not in the configuration"

                      # a migration to create the index
                      index = @database.loaded_schema(schema_name).table(table_name).index(index_name)
                      @generator.remove_index index

                    # If the index exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_index.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      log.info "    Index `#{index_name}` exists in both configuration and the database"

                      log.info "      Index `#{index_name}` is different"
                      # rebild the index
                      original_index = @database.loaded_schema(schema_name).table(table_name).index(index_name)
                      updated_index = @database.configured_schema(schema_name).table(table_name).index(index_name)
                      @generator.recreate_index original_index, updated_index
                      # does the description also need to be updated
                      if configuration_index[:description][:matches] == false
                        # if the description was removed
                        if configuration_index[:description].nil?
                          log.info "      Index `#{index_name}` description exists in database but not in the configuration"
                          @generator.remove_index_comment updated_index
                        else
                          log.info "      Index `#{index_name}` does not match"
                          @generator.set_index_comment updated_index
                        end
                      end

                    # If the index exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_index[:description][:matches] == false
                      log.info "    Index `#{index_name}` exists in both configuration and the database"

                      index = @database.configured_schema(schema_name).table(table_name).index(index_name)
                      # if the description was removed
                      if configuration_index[:description].nil?
                        log.info "      Index `#{index_name}` description exists in database but not in the configuration"
                        @generator.remove_index_comment index
                      else
                        log.info "      Index `#{index_name}` description does not match"
                        @generator.set_index_comment index
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
