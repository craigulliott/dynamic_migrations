# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module ValidationsLoader
          def create_database_validations_cache
            connection.exec(<<~SQL)
              CREATE MATERIALIZED VIEW public.dynamic_migrations_validations_cache as
                SELECT table_constraints.table_schema as schema_name,
                  table_constraints.table_name,
                  array_agg(col.column_name ORDER BY col.column_name) AS columns,
                  table_constraints.constraint_name as validation_name,
                  pg_get_expr(conbin, conrelid, true) as check_clause,
                  obj_description(pgc.oid, 'pg_constraint') as description,
                  -- in case we need to update this query in a later version of DynamicMigrations
                  1 as table_version
                FROM information_schema.table_constraints
                JOIN information_schema.check_constraints
                  ON table_constraints.constraint_schema = check_constraints.constraint_schema
                  AND table_constraints.constraint_name = check_constraints.constraint_name
                JOIN pg_namespace nsp ON nsp.nspname = check_constraints.constraint_schema
                JOIN pg_constraint pgc ON pgc.conname = check_constraints.constraint_name
                  AND pgc.connamespace = nsp.oid
                  AND pgc.contype = 'c'
                JOIN information_schema.columns col
                  ON col.table_schema = table_constraints.table_schema
                  AND col.table_name = table_constraints.table_name
                  AND col.ordinal_position = ANY(pgc.conkey)
                WHERE table_constraints.constraint_schema != 'information_schema'
                  AND table_constraints.constraint_schema != 'postgis'
                  AND left(table_constraints.constraint_schema, 3) != 'pg_'
                GROUP BY
                  pgc.oid,
                  table_constraints.table_schema,
                  table_constraints.table_name,
                  table_constraints.constraint_name,
                  check_constraints.check_clause;
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

              table[validation_name] = {
                columns: row["columns"].gsub(/\A\{/, "").gsub(/\}\Z/, "").split(",").map { |column_name| column_name.to_sym },
                check_clause: row["check_clause"],
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
