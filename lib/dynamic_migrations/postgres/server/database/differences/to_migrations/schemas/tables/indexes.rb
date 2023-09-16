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
                    index_names = (configuration_indexes.keys + database_indexes.keys).uniq
                    index_names.each do |index_name|
                      process_index schema_name, table_name, index_name, configuration_indexes[index_name] || {}, database_indexes[index_name] || {}
                    end
                  end

                  def process_index schema_name, table_name, index_name, configuration_index, database_index
                    # If the index exists in the configuration but not in the database
                    # then we have to create it.
                    if configuration_index[:exists] == true && !database_index[:exists]
                      # a migration to create the index
                      index = @database.configured_schema(schema_name).table(table_name).index(index_name)
                      @generator.add_index index

                    # If the schema exists in the database but not in the configuration
                    # then we need to delete it.
                    elsif database_index[:exists] == true && !configuration_index[:exists]
                      # a migration to create the index
                      index = @database.loaded_schema(schema_name).table(table_name).index(index_name)
                      @generator.remove_index index

                    # If the index exists in both the configuration and database representations
                    # but the definition (except description, which is handled seeprately below) is different
                    # then we need to update the definition.
                    elsif configuration_index.except(:exists, :description).filter { |name, attributes| attributes[:matches] == false }.any?
                      # rebild the index
                      original_index = @database.loaded_schema(schema_name).table(table_name).index(index_name)
                      updated_index = @database.configured_schema(schema_name).table(table_name).index(index_name)
                      @generator.recreate_index original_index, updated_index
                      # does the description also need to be updated
                      if configuration_index[:description][:matches] == false
                        # if the description was removed
                        if configuration_index[:description].nil?
                          @generator.remove_index_comment updated_index
                        else
                          @generator.set_index_comment updated_index
                        end
                      end

                    # If the index exists in both the configuration and database representations
                    # but the description is different then we need to update the description.
                    elsif configuration_index[:description][:matches] == false
                      index = @database.configured_schema(schema_name).table(table_name).index(index_name)
                      # if the description was removed
                      if configuration_index[:description].nil?
                        @generator.remove_index_comment index
                      else
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
