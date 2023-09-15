# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module StructureLoader
          def create_database_structure_cache
            connection.exec(<<~SQL)
              CREATE MATERIALIZED VIEW public.dynamic_migrations_structure_cache AS
                SELECT
                  -- Name of the schema containing the table
                  schemata.schema_name,
                  -- Name of the table
                  tables.table_name,
                  -- The comment which has been added to the table (if any)
                  table_description.description AS table_description,
                  -- Name of the column
                  columns.column_name,
                  -- The comment which has been added to the column (if any)
                  column_description.description AS column_description,
                  -- Default expression of the column
                  columns.column_default,
                  -- YES if the column is possibly nullable, NO if
                  -- it is known not nullable
                  columns.is_nullable,
                  -- The formatted data type (such as integer, char(5) or numeric(12,2)[])
                  CASE
                  WHEN tables.table_name IS NOT NULL THEN
                  (
                    SELECT format_type(atttypid,atttypmod) FROM pg_attribute a
                      WHERE a.attrelid = concat('"', schemata.schema_name, '"', '.', '"', tables.table_name, '"')::regclass
                      AND attnum = columns.ordinal_position
                  )
                  END AS data_type,
                  -- is this an emum
                  EXISTS (
                    SELECT 1
                    FROM pg_type typ
                      INNER JOIN pg_enum enu ON typ.oid = enu.enumtypid
                    WHERE typ.typname = columns.udt_name
                  ) AS is_enum,
                  -- If data_type identifies an interval type, this column contains
                  -- the specification which fields the intervals include for this
                  -- column, e.g., YEAR TO MONTH, DAY TO SECOND, etc. If no field
                  -- restrictions were specified (that is, the interval accepts all
                  -- fields), and for all other data types, this field is null.
                  columns.interval_type
                FROM information_schema.schemata
                LEFT JOIN information_schema.tables ON schemata.schema_name = tables.table_schema AND left(tables.table_name, 3) != 'pg_'
                LEFT JOIN information_schema.columns ON tables.table_name = columns.table_name AND schemata.schema_name = columns.table_schema
                -- required for the column and table description/comment joins
                LEFT JOIN pg_catalog.pg_statio_all_tables ON pg_statio_all_tables.schemaname = schemata.schema_name AND pg_statio_all_tables.relname = tables.table_name
                -- required for the table description/comment
                LEFT JOIN pg_catalog.pg_description table_description ON table_description.objoid = pg_statio_all_tables.relid AND table_description.objsubid = 0
                -- required for the column description/comment
                LEFT JOIN pg_catalog.pg_description column_description ON column_description.objoid = pg_statio_all_tables.relid AND column_description.objsubid = columns.ordinal_position
                WHERE schemata.schema_name != 'information_schema'
                  AND schemata.schema_name != 'postgis'
                  AND left(schemata.schema_name, 3) != 'pg_'
                -- order by the schema and table names alphabetically, then by the column position in the table
                ORDER BY schemata.schema_name, tables.table_schema, columns.ordinal_position
            SQL
            connection.exec(<<~SQL)
              COMMENT ON MATERIALIZED VIEW public.dynamic_migrations_structure_cache IS 'A cached representation of the database structure. This is used by the dynamic migrations library and is created automatically and updated automatically after migrations have run.';
            SQL
          end

          def refresh_database_structure_cache
            connection.exec(<<~SQL)
              REFRESH MATERIALIZED VIEW public.dynamic_migrations_structure_cache
            SQL
          rescue PG::UndefinedTable
            create_database_structure_cache
          end

          # fetch all columns from the database and build and return a
          # useful hash representing the structure of your database
          def fetch_structure
            begin
              rows = connection.exec(<<~SQL)
                SELECT * FROM public.dynamic_migrations_structure_cache
              SQL
            rescue PG::UndefinedTable
              create_database_structure_cache
              rows = connection.exec(<<~SQL)
                SELECT * FROM public.dynamic_migrations_structure_cache
              SQL
            end

            schemas = {}
            rows.each do |row|
              schema_name = row["schema_name"].to_sym
              schema = schemas[schema_name] ||= {
                tables: {}
              }

              unless row["table_name"].nil?
                table_name = row["table_name"].to_sym
                table = schema[:tables][table_name] ||= {
                  description: row["table_description"],
                  columns: {}
                }

                unless row["column_name"].nil?
                  column_name = row["column_name"].to_sym
                  column = table[:columns][column_name] ||= {}

                  column[:data_type] = row["data_type"].to_sym
                  column[:null] = row["is_nullable"] == "YES"
                  column[:is_enum] = row["is_enum"] == "TRUE"
                  column[:default] = row["column_default"]
                  column[:description] = row["column_description"]
                  column[:interval_type] = row["interval_type"].nil? ? nil : row["interval_type"].to_sym
                end
              end
            end
            schemas
          end

          # returns a list of the schema names in this database
          def fetch_schema_names
            rows = connection.exec(<<~SQL)
              SELECT schema_name
                FROM information_schema.schemata;
            SQL
            schema_names = rows.map { |row| row["schema_name"] }
            schema_names.reject! { |schema_name| schema_name == "information_schema" }
            schema_names.reject! { |schema_name| schema_name == "public" }
            schema_names.reject! { |schema_name| schema_name.start_with? "pg_" }
            schema_names.sort
          end

          # returns a list of the table names in the provided schema
          def fetch_table_names schema_name
            rows = connection.exec_params(<<~SQL, [schema_name.to_s])
              SELECT table_name FROM information_schema.tables
                WHERE table_schema = $1
            SQL
            table_names = rows.map { |row| row["table_name"] }
            table_names.reject! { |table_name| table_name.start_with? "pg_" }
            table_names.sort
          end
        end
      end
    end
  end
end
