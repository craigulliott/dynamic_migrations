# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module LoadedExtensions
          class LoadedExtensionAlreadyExistsError < StandardError
          end

          # adds a new loaded extension for this database
          def add_loaded_extension extension_name
            raise ExpectedSymbolError, extension_name unless extension_name.is_a? Symbol
            if has_loaded_extension? extension_name
              raise(LoadedExtensionAlreadyExistsError, "Loaded extension #{extension_name} already exists")
            end
            # sort the hash so that the extensions are in alphabetical order by name
            @loaded_extensions[extension_name] = true
            sorted_extensions = {}
            @loaded_extensions.keys.sort.each do |extension_name|
              sorted_extensions[extension_name] = true
            end
            @loaded_extensions = sorted_extensions
          end

          # returns true if this table has a loaded extension with the provided name, otherwise false
          def has_loaded_extension? extension_name
            raise ExpectedSymbolError, extension_name unless extension_name.is_a? Symbol
            @loaded_extensions.key? extension_name
          end

          # returns an array of this tables loaded extensions
          def loaded_extensions
            @loaded_extensions.keys
          end
        end
      end
    end
  end
end
