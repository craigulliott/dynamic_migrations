# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Extensions
              def process_extension extension_name, configuration_extension, database_extension
                # if the extension exists in the configuration but not in the database
                # then we have to create it
                if configuration_extension[:exists] == true && database_extension[:exists] == false
                  # a migration to create the extension
                  @generator.create_extension extension_name

                # if the extension exists in the database but not in the configuration
                # then we need to delete it
                elsif configuration_extension[:exists] == false && database_extension[:exists] == true
                  # a migration to drop the extension
                  @generator.drop_extension extension_name
                end
              end
            end
          end
        end
      end
    end
  end
end
