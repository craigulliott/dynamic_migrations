# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module LoadedSchemasBuilder
          # recursively process the database and build all the schemas,
          # tables and columns
          def recursively_build_schemas_from_database
            validations = fetch_validations
            fetch_structure.each do |schema_name, schema_definition|
              schema = add_loaded_schema schema_name
              schema_validations = validations[schema_name]

              schema_definition[:tables].each do |table_name, table_definition|
                table = schema.add_table table_name, table_definition[:description]
                table_constraints = schema_validations && schema_validations[table_name]

                # add each table column
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

                # add any validations
                if table_constraints
                  table_constraints.each do |validation_name, validation_definition|
                    table.add_validation validation_name, validation_definition[:columns], validation_definition[:check_clause]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
