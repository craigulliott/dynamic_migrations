# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module Differences
          # generate and return a hash representation of the configured and loaded schemas
          # which includes metadata about the differences between the two
          def differences
            differences = {
              configuration: {},
              database: {}
            }
            # recursively process the configured and loaded schemas
            (configured_schemas + loaded_schemas).each do |schema|
              current_source = differences[schema.source]
              other_source_type = (schema.source == :configuration) ? :database : :configuration
              other_source = differences[other_source_type]

              # if this schema already exists for the current_source, then it was created by
              # the other source type, and we need to mark it as existing
              if current_source.key? schema.schema_name
                current_source[schema.schema_name][:exists] = true
              else
                # if it is the first time we are processing a schema with this name for the
                # current source, then create it
                current_source[schema.schema_name] = {
                  exists: true,
                  tables: {}
                }
              end

              # if this is the first time we are processing this schema for the other source
              # type, then add it and assume it is missing (if it is processed later, then
              # the exists flag will be set to true)
              other_source[schema.schema_name] ||= {
                exists: false,
                tables: {}
              }

              current_schema_tables = current_source[schema.schema_name][:tables]
              other_schema_tables = other_source[schema.schema_name][:tables]

              # process the tables for the current schema
              schema.tables.each do |table|
                # if this table already exists for the current_source schema, then it was
                # created by the other source type, and we need to mark it as existing
                if current_schema_tables.key? table.table_name
                  current_schema_tables[table.table_name][:exists] = true
                else
                  # if it is the first time we are processing a table with this name for the
                  # current source, then create it
                  current_schema_tables[table.table_name] = {
                    exists: true,
                    columns: {}
                  }
                end

                # if this is the first time we are processing this table for the other source
                # type, then add it and assume it is missing (if it is processed later, then
                # the exists flag will be set to true)
                other_schema_tables[table.table_name] ||= {
                  exists: false,
                  columns: {}
                }

                current_table_columns = current_schema_tables[table.table_name][:columns]
                other_table_columns = other_schema_tables[table.table_name][:columns]

                # process the columns for the current table
                table.columns.each do |column|
                  # if this column already exists for the current_source table, then it was
                  # created by the other source type, and we need to mark it as existing
                  if current_table_columns.key? column.column_name
                    current_table_columns[column.column_name][:exists] = true
                  else
                    # if it is the first time we are processing a column with this name for the
                    # current source, then create it
                    current_table_columns[column.column_name] = {
                      exists: true
                    }
                  end

                  # if this is the first time we are processing this column for the other source
                  # type, then add it and assume it is missing (if it is processed later, then
                  # the exists flag will be set to true)
                  other_table_columns[column.column_name] ||= {
                    exists: false
                  }
                end
              end
            end
            differences
          end
        end
      end
    end
  end
end
