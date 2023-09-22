# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table < Source
            # This module has all the tables methods for working with foreign keys
            module ForeignKeyConstraints
              class ForeignKeyConstraintDoesNotExistError < StandardError
              end

              class ForeignKeyConstraintAlreadyExistsError < StandardError
              end

              # returns the foreign_key_constraint object for the provided foreign_key_constraint name, and raises an
              # error if the foreign_key_constraint does not exist
              def foreign_key_constraint name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                raise ForeignKeyConstraintDoesNotExistError unless has_foreign_key_constraint? name
                @foreign_key_constraints[name]
              end

              # returns true if this table has a foreign_key_constraint with the provided name, otherwise false
              def has_foreign_key_constraint? name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @foreign_key_constraints.key? name
              end

              # returns an array of this tables foreign_key_constraints
              def foreign_key_constraints
                @foreign_key_constraints.values
              end

              def foreign_key_constraints_hash
                @foreign_key_constraints
              end

              # adds a new foreign_key_constraint to this table, and returns it
              def add_foreign_key_constraint name, column_names, foreign_schema_name, foreign_table_name, foreign_column_names, **foreign_key_constraint_options
                if has_foreign_key_constraint? name
                  raise(ForeignKeyConstraintAlreadyExistsError, "foreign_key_constraint #{name} already exists")
                end
                columns = column_names.map { |column_name| column column_name }
                foreign_schema = schema.database.schema foreign_schema_name, source
                foreign_table = foreign_schema.table foreign_table_name
                foreign_columns = foreign_column_names.map { |column_name| foreign_table.column column_name }
                included_target = self
                if included_target.is_a? Table
                  new_foreign_key_constraint = @foreign_key_constraints[name] = ForeignKeyConstraint.new source, included_target, columns, foreign_table, foreign_columns, name, **foreign_key_constraint_options
                else
                  raise ModuleIncludedIntoUnexpectedTargetError, included_target
                end
                # sort the hash so that the foreign_key_constraints are in alphabetical order by name
                sorted_foreign_key_constraints = {}
                @foreign_key_constraints.keys.sort.each do |name|
                  sorted_foreign_key_constraints[name] = @foreign_key_constraints[name]
                end
                @foreign_key_constraints = sorted_foreign_key_constraints
                # return the new foreign_key_constraint
                new_foreign_key_constraint
              end

              # called automatically from the other side of the foreign key constraint to keep track of the foreign key from both sides
              def add_remote_foreign_key_constraint foreign_key_constraint
                @remote_foreign_key_constraints << foreign_key_constraint
              end
            end
          end
        end
      end
    end
  end
end
