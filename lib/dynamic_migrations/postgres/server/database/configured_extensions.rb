# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module ConfiguredExtensions
          class ConfiguredExtensionAlreadyExistsError < StandardError
          end

          # adds a new configured extension for this database
          def add_configured_extension extension_name
            raise ExpectedSymbolError, extension_name unless extension_name.is_a? Symbol
            if has_configured_extension? extension_name
              raise(ConfiguredExtensionAlreadyExistsError, "Configured extension #{extension_name} already exists")
            end
            # sort the hash so that the extensions are in alphabetical order by name
            @configured_extensions[extension_name] = true
            sorted_extensions = {}
            @configured_extensions.keys.sort.each do |extension_name|
              sorted_extensions[extension_name] = true
            end
            @configured_extensions = sorted_extensions
          end

          # returns true if this table has a configured extension with the provided name, otherwise false
          def has_configured_extension? extension_name
            raise ExpectedSymbolError, extension_name unless extension_name.is_a? Symbol
            @configured_extensions.key? extension_name
          end

          # returns an array of this tables configured extensions
          def configured_extensions
            @configured_extensions.keys
          end
        end
      end
    end
  end
end
