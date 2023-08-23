# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      # This class represents a postgres database. A database can contain many different
      # schemas.
      class Database
        class ExpectedServerError < StandardError
        end

        include Connection
        include StructureLoader
        include ValidationsLoader
        include KeysAndUniqueConstraintsLoader
        include TriggersAndFunctionsLoader
        include LoadedSchemas
        include ConfiguredSchemas
        include LoadedSchemasBuilder
        include ConfiguredExtensions
        include LoadedExtensions
        include EnumsLoader
        include ExtensionsLoader

        attr_reader :server
        attr_reader :name

        # initialize a new object to represent a postgres database
        def initialize server, name
          raise ExpectedServerError, server unless server.is_a? Server
          raise ExpectedSymbolError, name unless name.is_a? Symbol
          @server = server
          @name = name
          @configured_schemas = {}
          @loaded_schemas = {}
          @configured_extensions = {}
          @loaded_extensions = {}
        end

        # if `source` is :configuration then returns the configured schema with
        # the provided name, if `source` is :database then returns the loaded
        # schema with the provided name, errors are raised if the requested
        # schema does not exist or an unexpected `source` value is provided
        def schema schema_name, source
          case source
          when :configuration
            configured_schema schema_name
          when :database
            loaded_schema schema_name
          else
            raise InvalidSourceError, source
          end
        end

        def differences
          Differences.new(self)
        end
      end
    end
  end
end
