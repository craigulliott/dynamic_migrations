# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module LoadedSchemasBuilder
          class UnexpectedConstrintTypeError < StandardError
          end

          # recursively process the database and build all the schemas,
          # tables and columns
          def recursively_build_schemas_from_database
            validations = fetch_validations
            fetch_structure.each do |schema_name, schema_definition|
              schema = add_loaded_schema schema_name
              schema_validations = validations[schema_name]

              schema_definition[:tables].each do |table_name, table_definition|
                table = schema.add_table table_name, table_definition[:description]
                table_validations = schema_validations && schema_validations[table_name]

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
                    udt_name: udt_name
                end

                # add any validations
                unless table_validations.nil?
                  table_validations.each do |validation_name, validation_definition|
                    table.add_validation validation_name, validation_definition[:columns], validation_definition[:check_clause]
                  end
                end
              end
            end

            # now that the structure has been loaded, we can add keys (foreign
            # keys need to be added last, because they can depend on tables from
            # different schemas)
            fetch_keys_and_unique_constraints.each do |schema_name, schema_definition|
              schema_definition.each do |table_name, keys_and_unique_constraints|
                table = loaded_schema(schema_name).table(table_name)
                keys_and_unique_constraints.each do |constraint_type, constraint_definitions|
                  constraint_definitions.each do |constraint_name, constraint_definition|
                    case constraint_type
                    when :PRIMARY_KEY
                      table.add_primary_key constraint_name, constraint_definition[:column_names], index_type: constraint_definition[:index_type]

                    when :FOREIGN_KEY
                      table.add_foreign_key_constraint constraint_name, constraint_definition[:column_names], constraint_definition[:foreign_schema_name], constraint_definition[:foreign_table_name], constraint_definition[:foreign_column_names], deferrable: constraint_definition[:deferrable], initially_deferred: constraint_definition[:initially_deferred]

                    when :UNIQUE
                      table.add_unique_constraint constraint_name, constraint_definition[:column_names], deferrable: constraint_definition[:deferrable], initially_deferred: constraint_definition[:initially_deferred], index_type: constraint_definition[:index_type]

                    else
                      raise UnexpectedConstrintTypeError, constraint_type
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
end
