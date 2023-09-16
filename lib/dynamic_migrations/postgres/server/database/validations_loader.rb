# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module ValidationsLoader
          def create_database_validations_cache
            connection.exec(<<~SQL)
              CREATE MATERIALIZED VIEW public.dynamic_migrations_validations_cache AS
                SELECT
                  nspname AS schema_name,
                  pg_constraint_class.relname AS table_name,
                  array_agg(columns.column_name ORDER BY columns.column_name) AS columns,
                  pg_get_constraintdef(pg_constraint.oid) AS check_clause,
                  conname AS validation_name,
                  obj_description(pg_constraint.oid, 'pg_constraint') AS description,
                  -- in case we need to update this query in a later version of DynamicMigrations
                  1 as table_version
                FROM pg_catalog.pg_constraint
                INNER JOIN pg_catalog.pg_class pg_constraint_class
                  ON pg_constraint_class.oid = pg_constraint.conrelid
                INNER JOIN pg_catalog.pg_namespace pg_constraint_namespace
                  ON pg_constraint_namespace.oid = connamespace
                JOIN information_schema.columns
                  ON columns.table_schema = nspname
                  AND columns.table_name = pg_constraint_class.relname
                  AND columns.ordinal_position = ANY(pg_constraint.conkey)
                  WHERE
                    contype = 'c'
                    AND nspname != 'information_schema'
                    AND nspname != 'postgis'
                    AND left(nspname, 3) != 'pg_'
                  GROUP BY
                    pg_constraint.oid,
                    nspname,
                    pg_constraint_class.relname,
                    conname;
            SQL
            connection.exec(<<~SQL)
              CREATE UNIQUE INDEX dynamic_migrations_validations_cache_index ON public.dynamic_migrations_validations_cache (schema_name, table_name, validation_name);
            SQL
            connection.exec(<<~SQL)
              COMMENT ON MATERIALIZED VIEW public.dynamic_migrations_validations_cache IS 'A cached representation of the database validations. This is used by the dynamic migrations library and is created automatically and updated automatically after migrations have run.';
            SQL
          end

          def refresh_database_validations_cache
            connection.exec(<<~SQL)
              REFRESH MATERIALIZED VIEW public.dynamic_migrations_validations_cache
            SQL
          rescue PG::UndefinedTable
            create_database_validations_cache
          end

          # fetch all columns from the database and build and return a
          # useful hash representing the validations of your database
          def fetch_validations
            begin
              rows = connection.exec(<<~SQL)
                SELECT * FROM public.dynamic_migrations_validations_cache
              SQL
            rescue PG::UndefinedTable
              create_database_validations_cache
              rows = connection.exec(<<~SQL)
                SELECT * FROM public.dynamic_migrations_validations_cache
              SQL
            end

            schemas = {}
            rows.each do |row|
              schema_name = row["schema_name"].to_sym
              schema = schemas[schema_name] ||= {}

              table_name = row["table_name"].to_sym
              table = schema[table_name] ||= {}

              validation_name = row["validation_name"].to_sym

              matches = row["check_clause"].match(/\ACHECK \((?<inner_clause>.*)\)\z/)
              if matches.nil?
                raise StandardError, "Unparsable check_clause #{row["check_clause"]}"
              end
              check_clause = matches[:inner_clause]

              table[validation_name] = {
                columns: row["columns"].gsub(/\A\{/, "").gsub(/\}\Z/, "").split(",").map { |column_name| column_name.to_sym },
                check_clause: check_clause,
                description: row["description"],
                deferrable: row["deferrable"] == "TRUE",
                initially_deferred: row["initially_deferred"] == "TRUE"
              }
            end
            schemas
          end
        end
      end
    end
  end
end
