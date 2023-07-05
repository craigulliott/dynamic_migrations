# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module KeysAndUniqueConstraintsLoader
          def create_database_keys_and_unique_constraints_cache
            connection.exec(<<~SQL)
              CREATE MATERIALIZED VIEW public.dynamic_migrations_keys_and_unique_constraints_cache as
                SELECT
                  c.conname AS constraint_name,
                  CASE c.contype
                    WHEN 'f'::"char" THEN 'FOREIGN_KEY'::text
                    WHEN 'p'::"char" THEN 'PRIMARY_KEY'::text
                    WHEN 'u'::"char" THEN 'UNIQUE'::text
                  END::information_schema.character_data AS constraint_type,
                  sch.nspname AS schema_name,
                  tbl.relname AS table_name,
                  ARRAY_AGG(col.attname ORDER BY u.attposition) AS column_names,
                  f_sch.nspname AS foreign_schema_name,
                  f_tbl.relname AS foreign_table_name,
                  -- null if is required to prevent indexes and unique constraints from being included
                  NULLIF(ARRAY_AGG(f_col.attname ORDER BY f_u.attposition), ARRAY[null]::name[]) AS foreign_column_names,
                  c.condeferrable as deferrable,
                  c.condeferred as initially_deferred,
                  am.amname as index_type,
                  1 as table_version
                FROM pg_constraint c
                LEFT JOIN LATERAL UNNEST(c.conkey)
                  WITH ORDINALITY AS u(attnum, attposition)
                  ON TRUE
                LEFT JOIN LATERAL UNNEST(c.confkey)
                  WITH ORDINALITY AS f_u(attnum, attposition)
                  ON f_u.attposition = u.attposition
                JOIN pg_class tbl
                  ON
                    tbl.oid = c.conrelid
                    AND left(tbl.relname, 3) != 'pg_'
                JOIN pg_namespace sch
                  ON
                    sch.oid = tbl.relnamespace
                    AND sch.nspname != 'information_schema'
                    AND sch.nspname != 'postgis'
                    AND left(sch.nspname, 3) != 'pg_'
                LEFT JOIN pg_attribute col
                  ON
                    (col.attrelid = tbl.oid
                    AND col.attnum = u.attnum)
                LEFT JOIN pg_class f_tbl
                  ON
                    f_tbl.oid = c.confrelid
                    AND left(f_tbl.relname, 3) != 'pg_'
                LEFT JOIN pg_namespace f_sch
                  ON
                    f_sch.oid = f_tbl.relnamespace
                    AND f_sch.nspname != 'information_schema'
                    AND f_sch.nspname != 'postgis'
                    AND left(f_sch.nspname, 3) != 'pg_'
                LEFT JOIN pg_attribute f_col
                  ON
                    f_col.attrelid = f_tbl.oid
                    AND f_col.attnum = f_u.attnum

                -- joins below to get the index type
                LEFT JOIN pg_class index_cls ON index_cls.relname = c.conname AND index_cls.relnamespace = sch.oid
                LEFT JOIN pg_index on index_cls.oid = pg_index.indexrelid AND tbl.oid = pg_index.indrelid
                LEFT JOIN pg_am am ON am.oid=index_cls.relam

                WHERE
                -- only FOREIGN_KEY, UNIQUE or PRIMARY_KEY
                c.contype in ('f', 'u', 'p')

              GROUP BY constraint_name, constraint_type, condeferrable, condeferred, schema_name, table_name, foreign_schema_name, foreign_table_name, am.amname
              ORDER BY schema_name, table_name;
            SQL
            connection.exec(<<~SQL)
              CREATE UNIQUE INDEX dynamic_migrations_keys_and_unique_constraints_cache_index ON public.dynamic_migrations_keys_and_unique_constraints_cache (schema_name, table_name, constraint_name);
            SQL
            connection.exec(<<~SQL)
              COMMENT ON MATERIALIZED VIEW public.dynamic_migrations_keys_and_unique_constraints_cache IS 'A cached representation of the database constraints. This is used by the dynamic migrations library and is created automatically and updated automatically after migrations have run.';
            SQL
          end

          # fetch all required data from the database and build and return a
          # useful hash representing the keys and indexes of your database
          def fetch_keys_and_unique_constraints
            begin
              rows = connection.exec_params(<<~SQL)
                SELECT * FROM public.dynamic_migrations_keys_and_unique_constraints_cache
              SQL
            rescue PG::UndefinedTable
              create_database_keys_and_unique_constraints_cache
              rows = connection.exec_params(<<~SQL)
                SELECT * FROM public.dynamic_migrations_keys_and_unique_constraints_cache
              SQL
            end

            schemas = {}
            rows.each do |row|
              schema_name = row["schema_name"].to_sym
              schema = schemas[schema_name] ||= {}

              table_name = row["table_name"].to_sym
              table = schema[table_name] ||= {}

              constraint_type = row["constraint_type"].to_sym
              constraints = table[constraint_type] ||= {}

              constraint_name = row["constraint_name"].to_sym

              column_names = row["column_names"].gsub(/\A\{/, "").gsub(/\}\Z/, "").split(",").map { |column_name| column_name.to_sym }

              if constraint_type == :FOREIGN_KEY
                foreign_schema_name = row["foreign_schema_name"].to_sym
                foreign_table_name = row["foreign_table_name"].to_sym
                foreign_column_names = row["foreign_column_names"].gsub(/\A\{/, "").gsub(/\}\Z/, "").split(",").map { |column_name| column_name.to_sym }
              else
                foreign_schema_name = nil
                foreign_table_name = nil
                foreign_column_names = nil
              end

              deferrable = row["deferrable"] == "TRUE"
              initially_deferred = row["initially_deferred"] == "TRUE"

              index_type = if row["index_type"].nil?
                nil
              else
                row["index_type"].to_sym
              end

              constraints[constraint_name] = {
                column_names: column_names,
                foreign_schema_name: foreign_schema_name,
                foreign_table_name: foreign_table_name,
                foreign_column_names: foreign_column_names,
                deferrable: deferrable,
                initially_deferred: initially_deferred,
                index_type: index_type
              }
            end
            schemas
          end
        end
      end
    end
  end
end
