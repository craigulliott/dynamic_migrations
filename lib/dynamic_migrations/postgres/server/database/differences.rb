# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ExpectedDatabaseError < StandardError
          end

          class TableRequiredError < StandardError
          end

          class SchemaRequiredError < StandardError
          end

          def initialize database
            raise ExpectedDatabaseError, database unless database.is_a? Database
            @database = database
          end

          # return a hash representing any differenced betweek the loaded and configured
          # versions of the current database
          def to_h
            {
              configuration: self.class.compare_schemas(@database.configured_schemas_hash, @database.loaded_schemas_hash),
              database: self.class.compare_schemas(@database.loaded_schemas_hash, @database.configured_schemas_hash)
            }
          end

          def self.compare_schemas schemas, comparison_schemas
            result = {}
            # the base schemas
            schemas.each do |schema_name, schema|
              # compare this schema to the equivilent in the comparison list
              # note that the comparison may be nil
              result[schema_name] = compare_schema schema, comparison_schemas[schema_name]
            end
            # look for any in the comparison list which were not in the base list
            comparison_schemas.each do |schema_name, schema|
              unless result.key? schema_name
                result[schema_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # compare two schemas and return an object which represents the provided `schema` and
          # any differences between it and the provided `comparison_schema`
          def self.compare_schema schema, comparison_schema
            raise SchemaRequiredError if schema.nil?

            comparison_tables = comparison_schema.nil? ? {} : comparison_schema.tables_hash
            {
              exists: true,
              tables: compare_tables(schema.tables_hash, comparison_tables)
            }
          end

          # compare two hash representations of a set of tables and return
          # an object which represents the provided `tables` and any differences
          # between it and the `comparison_tables`
          def self.compare_tables tables, comparison_tables
            result = {}
            # the base tables
            tables.each do |table_name, table|
              # compare this table to the equivilent in the comparison list
              # note that the comparison may be nil
              result[table_name] = compare_table(table, comparison_tables[table_name])
            end
            # look for any in the comparison list which were not in the base list
            comparison_tables.each do |table_name, table|
              unless result.key? table_name
                result[table_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # compare two tables and return an object which represents the provided `table` and
          # any differences between it and the provided `comparison_table`
          def self.compare_table table, comparison_table
            raise TableRequiredError if table.nil?

            primary_key = table.has_primary_key? ? table.primary_key : nil
            if comparison_table
              comparison_primary_key = comparison_table.has_primary_key? ? comparison_table.primary_key : nil
              comparison_columns = comparison_table.columns_hash
              comparison_validations = comparison_table.validations_hash
              comparison_foreign_key_constraints = comparison_table.foreign_key_constraints_hash
              comparison_unique_constraints = comparison_table.unique_constraints_hash
            else
              comparison_primary_key = {}
              comparison_columns = {}
              comparison_validations = {}
              comparison_foreign_key_constraints = {}
              comparison_unique_constraints = {}
            end
            {
              exists: true,
              description: {
                value: table.description,
                matches: (comparison_table && comparison_table.description == table.description) ? true : false
              },
              primary_key: compare_record(primary_key, comparison_primary_key, [
                :primary_key_name,
                :index_type
              ]),
              columns: compare_columns(table.columns_hash, comparison_columns),
              validations: compare_validations(table.validations_hash, comparison_validations),
              foreign_key_constraints: compare_foreign_key_constraints(table.foreign_key_constraints_hash, comparison_foreign_key_constraints),
              unique_constraints: compare_unique_constraints(table.unique_constraints_hash, comparison_unique_constraints)
            }
          end

          # compare two hash representations of a set of columns and return
          # an object which represents the provided `columns` and any differences
          # between it and the `comparison_columns`
          def self.compare_columns columns, comparison_columns
            result = {}
            # the base columns
            columns.each do |column_name, column|
              # compare this column to the equivilent in the comparison list
              result[column_name] = compare_record column, comparison_columns[column_name], [
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
              ]
            end
            # look for any columns in the comparison list which were not in the base list
            comparison_columns.each do |column_name, column|
              unless result.key? column_name
                result[column_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # compare two hash representations of a set of unique_constraints and return
          # an object which represents the provided `unique_constraints` and any differences
          # between it and the `comparison_unique_constraints`
          def self.compare_unique_constraints unique_constraints, comparison_unique_constraints
            result = {}
            # the base unique_constraints
            unique_constraints.each do |unique_constraint_name, unique_constraint|
              # compare this unique_constraint to the equivilent in the comparison list
              result[unique_constraint_name] = compare_record unique_constraint, comparison_unique_constraints[unique_constraint_name], [
                :column_names,
                :index_type,
                :deferrable,
                :initially_deferred
              ]
            end
            # look for any unique_constraints in the comparison list which were not in the base list
            comparison_unique_constraints.each do |unique_constraint_name, unique_constraint|
              unless result.key? unique_constraint_name
                result[unique_constraint_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # compare two hash representations of a set of indexes and return
          # an object which represents the provided `indexes` and any differences
          # between it and the `comparison_indexes`
          def self.compare_indexes indexes, comparison_indexes
            result = {}
            # the base indexes
            indexes.each do |index_name, index|
              # compare this index to the equivilent in the comparison list
              result[index_name] = compare_record index, comparison_indexes[index_name], [
                :column_names,
                :unique,
                :where,
                :type,
                :deferrable,
                :initially_deferred,
                :order,
                :nulls_position
              ]
            end
            # look for any indexes in the comparison list which were not in the base list
            comparison_indexes.each do |index_name, index|
              unless result.key? index_name
                result[index_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # compare two hash representations of a set of validations and return
          # an object which represents the provided `validations` and any differences
          # between it and the `comparison_validations`
          def self.compare_validations validations, comparison_validations
            result = {}
            # the base validations
            validations.each do |validation_name, validation|
              # compare this validation to the equivilent in the comparison list
              result[validation_name] = compare_record validation, comparison_validations[validation_name], [
                :check_clause,
                :column_names,
                :deferrable,
                :initially_deferred
              ]
            end
            # look for any validations in the comparison list which were not in the base list
            comparison_validations.each do |validation_name, validation|
              unless result.key? validation_name
                result[validation_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # compare two hash representations of a set of foreign key constraints and return
          # an object which represents the provided `foreign_key_constraints` and any differences
          # between it and the `comparison_foreign_key_constraints`
          def self.compare_foreign_key_constraints foreign_key_constraints, comparison_foreign_key_constraints
            result = {}
            # the base foreign_key_constraints
            foreign_key_constraints.each do |foreign_key_constraint_name, foreign_key_constraint|
              # compare this foreign_key_constraint to the equivilent in the comparison list
              result[foreign_key_constraint_name] = compare_record foreign_key_constraint, comparison_foreign_key_constraints[foreign_key_constraint_name], [
                :column_names,
                :foreign_schema_name,
                :foreign_table_name,
                :foreign_column_names,
                :deferrable,
                :initially_deferred
              ]
            end
            # look for any foreign_key_constraints in the comparison list which were not in the base list
            comparison_foreign_key_constraints.each do |foreign_key_constraint_name, foreign_key_constraint|
              unless result.key? foreign_key_constraint_name
                result[foreign_key_constraint_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # Accepts an optional base and comparison objects, and a list of methods.
          # Returns a hash representing the base record and all the data which it
          # is returned for each mehod in the provided method list and any differences
          # it and the comparison.
          def self.compare_record base, comparison, method_list
            if base.nil?
              {
                exists: false
              }
            else
              result = {
                exists: true
              }
              method_list.each do |method_name|
                result[method_name] = {
                  value: base.send(method_name),
                  matches: (comparison && comparison.send(method_name) == base.send(method_name)) ? true : false
                }
              end
              result
            end
          end
        end
      end
    end
  end
end
