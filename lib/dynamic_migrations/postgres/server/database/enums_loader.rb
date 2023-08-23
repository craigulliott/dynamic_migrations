# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module EnumsLoader
          def fetch_enums
            rows = connection.exec(<<~SQL)
              SELECT
                n.nspname AS schema_name,
                t.typname AS enum_name,
                e.enumlabel AS enum_value,
                obj_description(e.enumtypid, 'pg_type') as enum_description
              FROM pg_type t
                JOIN pg_enum e ON t.oid = e.enumtypid
                JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
                ORDER BY enumsortorder
            SQL

            schemas = {}
            rows.each do |row|
              schema_name = row["schema_name"].to_sym
              enum_name = row["enum_name"].to_sym
              enum_value = row["enum_value"].to_sym

              schema = schemas[schema_name] ||= {}
              enum = schema[enum_name] ||= {
                values: [],
                description: row["enum_description"]
              }
              enum[:values] << enum_value
            end
            schemas
          end
        end
      end
    end
  end
end
