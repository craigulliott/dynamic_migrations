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
                  table.add_column column_name, column_definition[:data_type],
                    null: column_definition[:null],
                    default: column_definition[:default],
                    description: column_definition[:description],
                    interval_type: column_definition[:interval_type]
                end

                # add any validations
                table_validations&.each do |validation_name, validation_definition|
                  table.add_validation validation_name, validation_definition[:columns], validation_definition[:check_clause], description: validation_definition[:description], deferrable: validation_definition[:deferrable], initially_deferred: validation_definition[:initially_deferred]
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
                    when :primary_key
                      table.add_primary_key constraint_name, constraint_definition[:column_names], description: constraint_definition[:description]

                    when :foreign_key
                      table.add_foreign_key_constraint constraint_name, constraint_definition[:column_names], constraint_definition[:foreign_schema_name], constraint_definition[:foreign_table_name], constraint_definition[:foreign_column_names], description: constraint_definition[:description], deferrable: constraint_definition[:deferrable], initially_deferred: constraint_definition[:initially_deferred], on_delete: constraint_definition[:on_delete], on_update: constraint_definition[:on_update]

                    when :unique
                      table.add_unique_constraint constraint_name, constraint_definition[:column_names], description: constraint_definition[:description], deferrable: constraint_definition[:deferrable], initially_deferred: constraint_definition[:initially_deferred], index_type: constraint_definition[:index_type]

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
