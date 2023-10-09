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

          class FunctionRequiredError < StandardError
          end

          class SchemaRequiredError < StandardError
          end

          def initialize database
            @logger = Logging.logger[self]

            raise ExpectedDatabaseError, database unless database.is_a? Database
            @database = database
          end

          # returns a hash of migrations for each schema which will bring the configured
          # loaded database structure into alignment with the configured database structure
          def to_migrations
            ToMigrations.new(@database, self).migrations
          end

          # return a hash representing any differenced betweek the loaded and configured
          # versions of the current database
          def to_h
            log.info "Building differences between configured and loaded database structure"

            # build progressively, so we can add logging around the two different opperations
            results = {}

            log.info "Comparing configured database structure to loaded database structure"
            results[:configuration] = {
              schemas: self.class.compare_schemas(@database.configured_schemas_hash, @database.loaded_schemas_hash),
              extensions: self.class.compare_extensions(@database.configured_extensions, @database.loaded_extensions)
            }

            log.info "Comparing loaded database structure to configured database structure"
            results[:database] = {
              schemas: self.class.compare_schemas(@database.loaded_schemas_hash, @database.configured_schemas_hash),
              extensions: self.class.compare_extensions(@database.loaded_extensions, @database.configured_extensions)
            }
            results
          end

          def self.compare_extensions extensions, comparison_extensions
            log.debug "Comparing Extensions"

            result = {}
            # the extensions
            extensions.each do |extension_name|
              # compare this extension to the equivilent in the comparison list
              # note that the comparison may be nil
              result[extension_name] = {
                exists: true
              }
            end
            # look for any in the comparison list which were not in the base list
            comparison_extensions.each do |extension_name|
              unless result.key? extension_name
                result[extension_name] = {
                  exists: false
                }
              end
            end
            result
          end

          def self.compare_schemas schemas, comparison_schemas
            log.debug "Comparing Schemas"

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

            log.debug "Comparing Schema `#{schema.name}`"

            comparison_tables = comparison_schema.nil? ? {} : comparison_schema.tables_hash
            comparison_functions = comparison_schema.nil? ? {} : comparison_schema.functions_hash
            comparison_enums = comparison_schema.nil? ? {} : comparison_schema.enums_hash
            {
              exists: true,
              tables: compare_tables(schema.tables_hash, comparison_tables),
              functions: compare_functions(schema.functions_hash, comparison_functions),
              enums: compare_enums(schema.enums_hash, comparison_enums)
            }
          end

          # compare two hash representations of a set of tables and return
          # an object which represents the provided `tables` and any differences
          # between it and the `comparison_tables`
          def self.compare_tables tables, comparison_tables
            log.debug "Comparing Tables"

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

            log.debug "Comparing Table `#{table.name}`"

            primary_key = table.has_primary_key? ? table.primary_key : nil
            if comparison_table
              comparison_primary_key = comparison_table.has_primary_key? ? comparison_table.primary_key : nil
              comparison_columns = comparison_table.columns_hash
              comparison_indexes = comparison_table.indexes_hash
              comparison_triggers = comparison_table.triggers_hash
              comparison_validations = comparison_table.validations_hash
              comparison_foreign_key_constraints = comparison_table.foreign_key_constraints_hash
              comparison_unique_constraints = comparison_table.unique_constraints_hash
            else
              comparison_primary_key = nil
              comparison_columns = {}
              comparison_indexes = {}
              comparison_triggers = {}
              comparison_validations = {}
              comparison_foreign_key_constraints = {}
              comparison_unique_constraints = {}
            end
            {
              exists: true,
              description: {
                value: table.description,
                matches: (comparison_table && comparison_table.description == table.description) || false
              },
              primary_key: compare_record(primary_key, comparison_primary_key, [
                :name,
                :column_names,
                :description
              ]),
              columns: compare_columns(table.columns_hash, comparison_columns),
              indexes: compare_indexes(table.indexes_hash, comparison_indexes),
              triggers: compare_triggers(table.triggers_hash, comparison_triggers),
              validations: compare_validations(table.validations_hash, comparison_validations),
              foreign_key_constraints: compare_foreign_key_constraints(table.foreign_key_constraints_hash, comparison_foreign_key_constraints),
              unique_constraints: compare_unique_constraints(table.unique_constraints_hash, comparison_unique_constraints)
            }
          end

          # compare two hash representations of a set of functions and return
          # an object which represents the provided `functions` and any differences
          # between it and the `comparison_functions`
          def self.compare_functions functions, comparison_functions
            log.debug "Comparing Functions"

            result = {}
            # the base functions
            functions.each do |function_name, function|
              result[function_name] = compare_record function, comparison_functions[function_name], [
                :normalized_definition,
                :description
              ]
            end
            # look for any in the comparison list which were not in the base list
            comparison_functions.each do |function_name, function|
              unless result.key? function_name
                result[function_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # compare two hash representations of a set of enums and return
          # an object which represents the provided `enums` and any differences
          # between it and the `comparison_enums`
          def self.compare_enums enums, comparison_enums
            log.debug "Comparing Enums"

            result = {}
            # the base enums
            enums.each do |enum_name, enum|
              result[enum_name] = compare_record enum, comparison_enums[enum_name], [
                :values,
                :description
              ]
            end
            # look for any in the comparison list which were not in the base list
            comparison_enums.each do |enum_name, enum|
              unless result.key? enum_name
                result[enum_name] = {
                  exists: false
                }
              end
            end
            result
          end

          # compare two hash representations of a set of columns and return
          # an object which represents the provided `columns` and any differences
          # between it and the `comparison_columns`
          def self.compare_columns columns, comparison_columns
            log.debug "Comparing Columns"

            result = {}
            # the base columns
            columns.each do |column_name, column|
              # compare this column to the equivilent in the comparison list
              result[column_name] = compare_record column, comparison_columns[column_name], [
                :data_type,
                :null,
                :default,
                :description,
                :interval_type
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

          # compare two hash representations of a set of triggers and return
          # an object which represents the provided `triggers` and any differences
          # between it and the `comparison_triggers`
          def self.compare_triggers triggers, comparison_triggers
            log.debug "Comparing Triggers"

            result = {}
            # the base triggers
            triggers.each do |trigger_name, trigger|
              # compare this trigger to the equivilent in the comparison list
              result[trigger_name] = compare_record trigger, comparison_triggers[trigger_name], [
                :action_timing,
                :event_manipulation,
                :action_order,
                :normalized_action_condition,
                :parameters,
                :action_orientation,
                :action_reference_old_table,
                :action_reference_new_table,
                :description
              ]
            end
            # look for any triggers in the comparison list which were not in the base list
            comparison_triggers.each do |trigger_name, trigger|
              unless result.key? trigger_name
                result[trigger_name] = {
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
            log.debug "Comparing Unique Constraints"

            result = {}
            # the base unique_constraints
            unique_constraints.each do |name, unique_constraint|
              # compare this unique_constraint to the equivilent in the comparison list
              result[name] = compare_record unique_constraint, comparison_unique_constraints[name], [
                :column_names,
                :description,
                :deferrable,
                :initially_deferred
              ]
            end
            # look for any unique_constraints in the comparison list which were not in the base list
            comparison_unique_constraints.each do |name, unique_constraint|
              unless result.key? name
                result[name] = {
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
            log.debug "Comparing Indexes"

            result = {}
            # the base indexes
            indexes.each do |name, index|
              # compare this index to the equivilent in the comparison list
              result[name] = compare_record index, comparison_indexes[name], [
                :column_names,
                :description,
                :unique,
                :where,
                :type,
                :order,
                :nulls_position
              ]
            end
            # look for any indexes in the comparison list which were not in the base list
            comparison_indexes.each do |name, index|
              unless result.key? name
                result[name] = {
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
            log.debug "Comparing Validations"

            result = {}
            # the base validations
            validations.each do |name, validation|
              # compare this validation to the equivilent in the comparison list
              result[name] = compare_record validation, comparison_validations[name], [
                :normalized_check_clause,
                :column_names,
                :description,
                :deferrable,
                :initially_deferred
              ]
            end
            # look for any validations in the comparison list which were not in the base list
            comparison_validations.each do |name, validation|
              unless result.key? name
                result[name] = {
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
            log.debug "Comparing Foreign Key Constraints"

            result = {}
            # the base foreign_key_constraints
            foreign_key_constraints.each do |name, foreign_key_constraint|
              # compare this foreign_key_constraint to the equivilent in the comparison list
              result[name] = compare_record foreign_key_constraint, comparison_foreign_key_constraints[name], [
                :column_names,
                :foreign_schema_name,
                :foreign_table_name,
                :foreign_column_names,
                :description,
                :deferrable,
                :initially_deferred,
                :on_delete,
                :on_update
              ]
            end
            # look for any foreign_key_constraints in the comparison list which were not in the base list
            comparison_foreign_key_constraints.each do |name, foreign_key_constraint|
              unless result.key? name
                result[name] = {
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
              type = base.class.name.split("::").last
              name = base.is_a?(Schema::Table::PrimaryKey) ? nil : base.name
              log.debug "  Comparing #{type} `#{name}`"

              result = {}
              method_list.each do |method_name|
                log.debug "    Comparing `#{method_name}`"

                matches = (comparison && comparison.send(method_name) == base.send(method_name)) || false
                result[method_name] = {
                  value: base.send(method_name),
                  matches: matches
                }
              end
              result[:exists] = true
              result
            end
          end

          def self.log
            @logger ||= Logging.logger[self]
          end

          def log
            @logger
          end
        end
      end
    end
  end
end
