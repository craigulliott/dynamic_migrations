# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            class UnexpectedDatabaseObjectError < StandardError
            end

            class UnexpectedDifferencesObjectError < StandardError
            end

            include Extensions
            include Schemas
            include Schemas::Functions
            include Schemas::Enums
            include Schemas::Tables
            include Schemas::Tables::Columns
            include Schemas::Tables::ForeignKeyConstraints
            include Schemas::Tables::Indexes
            include Schemas::Tables::PrimaryKey
            include Schemas::Tables::Triggers
            include Schemas::Tables::UniqueConstraints
            include Schemas::Tables::Validations

            def initialize database, differences
              raise UnexpectedDatabaseObjectError, database unless database.is_a? Database
              @database = database

              raise UnexpectedDifferencesObjectError, differences unless differences.is_a? Differences
              @differences = differences

              # the generator which will build the migrations
              @generator = Generator.new
            end

            def migrations
              # process all the extensions
              extension_names = differences[:configuration][:extensions].keys
              extension_names.each do |extension_name|
                process_extension extension_name, differences[:configuration][:extensions][extension_name], differences[:database][:extensions][extension_name]
              end

              # process all the schemas (we can fetch the schema names from either the
              # configuration or the database object)
              schema_names = differences[:configuration][:schemas].keys
              schema_names.each do |schema_name|
                process_schema schema_name, differences[:configuration][:schemas][schema_name], differences[:database][:schemas][schema_name]
              end

              # return the migrations organized by schema
              @generator.migrations
            end

            private

            def differences
              @differences_hash ||= @differences.to_h
            end
          end
        end
      end
    end
  end
end
