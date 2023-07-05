# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module StructureLoader
          def create_database_structure_cache
            connection.exec(<<~SQL)
              CREATE MATERIALIZED VIEW public.dynamic_migrations_structure_cache as
                SELECT
                  -- Name of the schema containing the table
                  schemata.schema_name,
                  -- Name of the table
                  tables.table_name,
                  -- The comment which has been added to the table (if any)
                  table_description.description as table_description,
                  -- Name of the column
                  columns.column_name,
                  -- The comment which has been added to the column (if any)
                  column_description.description as column_description,
                  -- Default expression of the column
                  columns.column_default,
                  -- YES if the column is possibly nullable, NO if
                  -- it is known not nullable
                  columns.is_nullable,
                  -- Data type of the column, if it is a built-in type,
                  -- or ARRAY if it is some array (in that case, see the
                  -- view element_types), else USER-DEFINED (in that case,
                  -- the type is identified in udt_name and associated
                  -- columns). If the column is based on a domain, this
                  -- column refers to the type underlying the domain (and
                  -- the domain is identified in domain_name and associated
                  -- columns).
                  columns.data_type,
                  -- If data_type identifies a character or bit string type,
                  -- the declared maximum length; null for all other data
                  -- types or if no maximum length was declared.
                  columns.character_maximum_length,
                  -- If data_type identifies a character type, the maximum
                  -- possible length in octets (bytes) of a datum; null for
                  -- all other data types. The maximum octet length depends
                  -- on the declared character maximum length (see above)
                  -- and the server encoding.
                  columns.character_octet_length,
                  -- If data_type identifies a numeric type, this column
                  -- contains the (declared or implicit) precision of the type
                  -- for this column. The precision indicates the number of
                  -- significant digits. It can be expressed in decimal (base 10)
                  -- or binary (base 2) terms, as specified in the column
                  -- numeric_precision_radix. For all other data types, this
                  -- column is null.
                  columns.numeric_precision,
                  -- If data_type identifies a numeric type, this column indicates
                  -- in which base the values in the columns numeric_precision and
                  -- numeric_scale are expressed. The value is either 2 or 10. For
                  -- all other data types, this column is null.
                  columns.numeric_precision_radix,
                  -- If data_type identifies an exact numeric type, this column
                  -- contains the (declared or implicit) scale of the type for this
                  -- column. The scale indicates the number of significant digits to
                  -- the right of the decimal point. It can be expressed in decimal
                  -- (base 10) or binary (base 2) terms, as specified in the column
                  -- numeric_precision_radix. For all other data types, this column
                  -- is null.
                  columns.numeric_scale,
                  -- If data_type identifies a date, time, timestamp, or interval
                  -- type, this column contains the (declared or implicit) fractional
                  -- seconds precision of the type for this column, that is, the
                  -- number of decimal digits maintained following the decimal point
                  -- in the seconds value. For all other data types, this column is
                  -- null.
                  columns.datetime_precision,
                  -- If data_type identifies an interval type, this column contains
                  -- the specification which fields the intervals include for this
                  -- column, e.g., YEAR TO MONTH, DAY TO SECOND, etc. If no field
                  -- restrictions were specified (that is, the interval accepts all
                    -- fields), and for all other data types, this field is null.
                  columns.interval_type,
                  -- Name of the schema that the column data type (the underlying
                  --type of the domain, if applicable) is defined in
                  columns.udt_schema,
                  -- Name of the column data type (the underlying type of the domain,
                  -- if applicable)
                  columns.udt_name,
                  -- YES if the column is updatable, NO if not (Columns in base tables
                    -- are always updatable, columns in views not necessarily)
                  columns.is_updatable
                FROM information_schema.schemata
                LEFT JOIN information_schema.tables ON schemata.schema_name = tables.table_schema AND left(tables.table_name, 3) != 'pg_'
                LEFT JOIN information_schema.columns ON tables.table_name = columns.table_name
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

          # fetch all columns from the database and build and return a
          # useful hash representing the structure of your database
          def fetch_structure
            begin
              rows = connection.exec_params(<<~SQL)
                SELECT * FROM public.dynamic_migrations_structure_cache
              SQL
            rescue PG::UndefinedTable
              create_database_structure_cache
              rows = connection.exec_params(<<~SQL)
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
                  column[:default] = row["column_default"]
                  column[:description] = row["column_description"]
                  column[:character_maximum_length] = row["character_maximum_length"].nil? ? nil : row["character_maximum_length"].to_i
                  column[:character_octet_length] = row["character_octet_length"].nil? ? nil : row["character_octet_length"].to_i
                  column[:numeric_precision] = row["numeric_precision"].nil? ? nil : row["numeric_precision"].to_i
                  column[:numeric_precision_radix] = row["numeric_precision_radix"].nil? ? nil : row["numeric_precision_radix"].to_i
                  column[:numeric_scale] = row["numeric_scale"].nil? ? nil : row["numeric_scale"].to_i
                  column[:datetime_precision] = row["datetime_precision"].nil? ? nil : row["datetime_precision"].to_i
                  column[:interval_type] = row["interval_type"].nil? ? nil : row["interval_type"].to_sym
                  column[:udt_schema] = row["udt_schema"].to_sym
                  column[:udt_name] = row["udt_name"].to_sym
                  column[:updatable] = row["is_updatable"] == "YES"
                end
              end
            end
            schemas
          end

          # recursively process the database and build all the schemas,
          # tables and columns
          def recursively_build_schemas_from_database
            fetch_structure.each do |schema_name, schema_definition|
              schema = add_loaded_schema schema_name

              schema_definition[:tables].each do |table_name, table_definition|
                table = schema.add_table table_name, table_definition[:description]

                table_definition[:columns].each do |column_name, column_definition|
                  # we only need these for arrays and user-defined types
                  # (user-defined is usually ENUMS)
                  if [:ARRAY, :"USER-DEFINED"].include? column_definition[:data_type]
                    udt_schema = column_definition[:udt_schema]
                    udt_name = column_definition[:udt_name]
                  else
                    udt_schema = nil
                    udt_name = nil
                  end

                  table.add_column column_name, column_definition[:data_type],
                    null: column_definition[:null],
                    default: column_definition[:default],
                    description: column_definition[:description],
                    character_maximum_length: column_definition[:character_maximum_length],
                    character_octet_length: column_definition[:character_octet_length],
                    numeric_precision: column_definition[:numeric_precision],
                    numeric_precision_radix: column_definition[:numeric_precision_radix],
                    numeric_scale: column_definition[:numeric_scale],
                    datetime_precision: column_definition[:datetime_precision],
                    udt_schema: udt_schema,
                    udt_name: udt_name,
                    updatable: column_definition[:updatable]
                end
              end
            end
          end

          # returns a list of the schema names in this database
          def fetch_schema_names
            rows = connection.exec(<<-SQL)
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
            rows = connection.exec_params(<<-SQL, [schema_name.to_s])
                  SELECT table_name FROM information_schema.tables
                    WHERE table_schema = $1
            SQL
            table_names = rows.map { |row| row["table_name"] }
            table_names.reject! { |table_name| table_name.start_with? "pg_" }
            table_names.sort
          end

          # returns a list of columns definitions for the provided table
          def fetch_columns schema_name, table_name
            rows = connection.exec_params(<<-SQL, [schema_name.to_s, table_name.to_s])
                  SELECT column_name, is_nullable, data_type, character_octet_length, column_default, numeric_precision, numeric_precision_radix, numeric_scale, udt_schema, udt_name
                    FROM information_schema.columns
                  WHERE table_schema = $1
                    AND table_name = $2;
            SQL
            rows.map do |row|
              {
                column_name: row["column_name"].to_sym,
                type: row["data_type"].to_sym
              }
            end
          end
        end
      end
    end
  end
end
