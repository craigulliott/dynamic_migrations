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
                if configuration_extension[:exists] == true && !database_extension[:exists]
                  log.debug "Extension `#{extension_name}` exists in configuration but not in the database"
                  # a migration to create the extension
                  @generator.enable_extension extension_name

                # if the extension exists in the database but not in the configuration
                # then we need to delete it
                elsif database_extension[:exists] == true && !configuration_extension[:exists]
                  log.debug "Extension `#{extension_name}` exists in database but not in the configuration"
                  # a migration to drop the extension
                  if Postgres.remove_unused_extensions?
                    @generator.disable_extension extension_name
                  else
                    log.warn "Skipping removal of extension `#{extension_name}` due to configuration setting"
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
