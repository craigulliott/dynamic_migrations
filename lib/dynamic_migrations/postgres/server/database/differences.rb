# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module Differences
          TRACKED_COLUMN_ATTRIBUTES = [
            :data_type,
            :null,
            :default,
            :description,
            :character_maximum_length,
            :character_octet_length,
            :numeric_precision,
            :numeric_precision_radix,
            :numeric_scale,
            :datetime_precision,
            :interval_type,
            :udt_schema,
            :udt_name,
            :updatable
          ].freeze

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

              # if this is the first time we are processing this schema for the other source
              # type, then add it and assume it is missing (if it is processed later, then
              # the exists flag will be set to true and the other fields will be set)
              other_source[schema.schema_name] ||= {
                exists: false,
                tables: {}
              }

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

              current_schema_tables = current_source[schema.schema_name][:tables]
              other_schema_tables = other_source[schema.schema_name][:tables]

              # process the tables for the current schema
              schema.tables.each do |table|
                # if this is the first time we are processing this table for the other source
                # type, then add it and assume it is missing (if it is processed later, then
                # the exists flag will be set to true and the other fields will be set)
                other_schema_tables[table.table_name] ||= {
                  exists: false,
                  columns: {},
                  validations: {}
                }

                # if this table already exists for the current_source schema, then it was
                # created by the other source type, and we need to mark it as existing
                if current_schema_tables.key? table.table_name
                  # note that the table exists
                  current_schema_tables[table.table_name][:exists] = true
                  # update the description metadata
                  current_schema_tables[table.table_name][:description] = {
                    value: table.description,
                    matches: table.description == other_schema_tables[table.table_name][:exists] && other_schema_tables[table.table_name][:description][:value]
                  }
                  # If this table exists on the other_schema_tables, then update its value of `matches` for
                  # the description
                  if other_schema_tables[table.table_name][:exists]
                    other_schema_tables[table.table_name][:description][:matches] = table.description == other_schema_tables[table.table_name][:description][:value]
                  end
                else
                  # if it is the first time we are processing a table with this name for the
                  # current source, then create it
                  current_schema_tables[table.table_name] = {
                    exists: true,
                    columns: {},
                    validations: {},
                    description: {
                      value: table.description,
                      # assume the description does not match until we prove otherwise
                      matches: false
                    }
                  }
                end

                current_table_columns = current_schema_tables[table.table_name][:columns]
                other_table_columns = other_schema_tables[table.table_name][:columns]

                # process the columns for the current table
                table.columns.each do |column|
                  # if this is the first time we are processing this column for the other source
                  # type, then add it and assume it is missing (if it is processed later, then
                  # the exists flag will be set to true and the other fields will be set)
                  other_table_columns[column.column_name] ||= {
                    exists: false
                  }

                  # if this column already exists for the current_source table, then it was
                  # created by the other source type, and we need to mark it as existing
                  if current_table_columns.key? column.column_name
                    # note that the column exists
                    current_table_columns[column.column_name][:exists] = true
                    # update the other tracked attributes
                    # initialize tracking for all the column attributes
                    TRACKED_COLUMN_ATTRIBUTES.each do |attribute_name|
                      current_table_columns[column.column_name][attribute_name] = {
                        value: column.send(attribute_name),
                        matches: other_table_columns[column.column_name][:exists] && column.send(attribute_name) == other_table_columns[column.column_name][attribute_name][:value]
                      }
                    end
                    # If this column exists on the other_schema_tables, then update its value of `matches` for
                    # each of the tracked attributes
                    if other_table_columns[column.column_name][:exists]
                      TRACKED_COLUMN_ATTRIBUTES.each do |attribute_name|
                        other_table_columns[column.column_name][attribute_name][:matches] = column.send(attribute_name) == other_table_columns[column.column_name][attribute_name][:value]
                      end
                    end
                  else
                    # if it is the first time we are processing a column with this name for the
                    # current source, then create it
                    current_table_columns[column.column_name] = {
                      exists: true
                    }
                    # initialize tracking for all the column attributes
                    TRACKED_COLUMN_ATTRIBUTES.each do |attribute_name|
                      current_table_columns[column.column_name][attribute_name] = {
                        value: column.send(attribute_name),
                        # assume the description does not match until we prove otherwise
                        matches: false
                      }
                    end
                  end
                end

                current_table_constraints = current_schema_tables[table.table_name][:validations]
                other_table_constraints = other_schema_tables[table.table_name][:validations]

                # process the validations for the current table
                table.validations.each do |validation|
                  # if this is the first time we are processing this validation for the other source
                  # type, then add it and assume it is missing (if it is processed later, then
                  # the exists flag will be set to true and the other fields will be set)
                  other_table_constraints[validation.validation_name] ||= {
                    exists: false
                  }

                  # if this validation already exists for the current_source table, then it was
                  # created by the other source type, and we need to mark it as existing
                  if current_table_constraints.key? validation.validation_name
                    # note that the validation exists
                    current_table_constraints[validation.validation_name][:exists] = true
                    # update the check_clause metadata
                    current_table_constraints[validation.validation_name][:check_clause] = {
                      value: validation.check_clause,
                      matches: validation.check_clause == other_table_constraints[validation.validation_name][:exists] && other_table_constraints[validation.validation_name][:check_clause][:value]
                    }
                    # If this validation exists on the other_table_constraints, then update its value of `matches` for
                    # the check_clause
                    if other_table_constraints[validation.validation_name][:exists]
                      other_table_constraints[validation.validation_name][:check_clause][:matches] = validation.description == other_table_constraints[validation.validation_name][:check_clause][:value]
                    end
                  else
                    # if it is the first time we are processing a validation with this name for the
                    # current source, then create it
                    current_table_constraints[validation.validation_name] = {
                      exists: true,
                      check_clause: {
                        value: validation.check_clause,
                        # assume the check_clause does not match until we prove otherwise
                        matches: false
                      }

                    }
                  end
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
