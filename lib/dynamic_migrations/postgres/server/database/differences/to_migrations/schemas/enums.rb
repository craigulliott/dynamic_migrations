# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Enums
                def process_enums schema_name, configuration_enums, database_enums
                  # process all the enums
                  enum_names = (configuration_enums.keys + database_enums.keys).uniq
                  enum_names.each do |enum_name|
                    process_enum schema_name, enum_name, configuration_enums[enum_name] || {}, database_enums[enum_name] || {}
                  end
                end

                def process_enum schema_name, enum_name, configuration_enum, database_enum
                  # If the enum exists in the configuration but not in the database
                  # then we have to create it.
                  if configuration_enum[:exists] == true && database_enum[:exists] == false
                    # a migration to create the enum
                    enum = @database.configured_schema(schema_name).enum(enum_name)
                    @generator.create_enum enum
                    # optionally add the description
                    if enum.has_description?
                      @generator.set_enum_comment enum
                    end

                  # If the schema exists in the database but not in the configuration
                  # then we need to delete it.
                  elsif configuration_enum[:exists] == false && database_enum[:exists] == true
                    # a migration to create the enum
                    enum = @database.loaded_schema(schema_name).enum(enum_name)
                    @generator.drop_enum enum

                  # If the enum exists in both the configuration and database representations
                  # but the values is different then we need to update the values.
                  elsif configuration_enum[:values][:matches] == false
                    original_enum = @database.loaded_schema(schema_name).enum(enum_name)
                    updated_enum = @database.configured_schema(schema_name).enum(enum_name)
                    @generator.update_enum original_enum, updated_enum
                    # does the description also need to be updated
                    if configuration_enum[:description][:matches] == false
                      # if the description was removed
                      if configuration_enum[:description].nil?
                        @generator.remove_enum_comment updated_enum
                      else
                        @generator.set_enum_comment updated_enum
                      end
                    end

                  # If the enum exists in both the configuration and database representations
                  # but the description is different then we need to update the description.
                  elsif configuration_enum[:description][:matches] == false
                    enum = @database.configured_schema(schema_name).enum(enum_name)
                    # if the description was removed
                    if configuration_enum[:description].nil?
                      @generator.remove_enum_comment enum
                    else
                      @generator.set_enum_comment enum
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
