# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module Loader
          # fetch all columns from the database and build and return a
          # useful hash representing the structure of your database
          def fetch_all include_public_schema = false
            rows = connection.exec_params(<<~SQL)
              SELECT
                -- Name of the schema containing the table
                schemata.schema_name,
                -- Name of the table
                tables.table_name,
                -- Name of the column
                columns.column_name,
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
              LEFT JOIN information_schema.tables ON schemata.schema_name = tables.table_schema
              LEFT JOIN information_schema.columns on tables.table_name = columns.table_name
                WHERE schemata.schema_name != 'information_schema'
                  AND schemata.schema_name != 'postgis'
                  AND left(schemata.schema_name, 3) != 'pg_'
                  #{include_public_schema ? "" : "AND schemata.schema_name != 'public'"}
            SQL

            schemas = {}
            rows.each do |row|
              schema_name = row["schema_name"].to_sym
              schema = schemas[schema_name] ||= {}

              unless row["table_name"].nil?
                table_name = row["table_name"].to_sym
                table = schema[table_name] ||= {}

                unless row["column_name"].nil?
                  column_name = row["column_name"].to_sym
                  column = table[column_name] ||= {}

                  column[:default] = row["column_default"]
                  column[:null] = row["is_nullable"] == "YES"

                  data_type = DataType.new(row["data_type"].to_sym)
                  column[:data_type] = data_type.name

                  column[:character_maximum_length] = row["character_maximum_length"].nil? ? nil : row["character_maximum_length"].to_i
                  column[:character_octet_length] = row["character_octet_length"].nil? ? nil : row["character_octet_length"].to_i
                  column[:numeric_precision] = row["numeric_precision"].nil? ? nil : row["numeric_precision"].to_i
                  column[:numeric_precision_radix] = row["numeric_precision_radix"].nil? ? nil : row["numeric_precision_radix"].to_i
                  column[:numeric_scale] = row["numeric_scale"].nil? ? nil : row["numeric_scale"].to_i
                  column[:datetime_precision] = row["datetime_precision"].nil? ? nil : row["datetime_precision"].to_i
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
          def recursively_build_schema_from_database
            fetch_all.each do |schema_name, tables|
              schema = add_loaded_schema schema_name

              tables.each do |table_name, columns|
                table = schema.add_table table_name

                columns.each do |column_name, column_config|
                  table.add_column column_name, column_config[:data_type]
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
            schema_names
          end

          # returns a list of the table names in the provided schema
          def fetch_table_names schema_name
            rows = connection.exec_params(<<-SQL, [schema_name.to_s])
                  SELECT table_name FROM information_schema.tables
                    WHERE table_schema = $1
            SQL
            rows.map { |row| row["table_name"] }
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
