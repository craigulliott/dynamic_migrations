# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table < Source
            # This module has all the tables methods for working with unique_constraints
            module UniqueConstraints
              class UniqueConstraintDoesNotExistError < StandardError
              end

              class UniqueConstraintAlreadyExistsError < StandardError
              end

              # returns the unique_constraint object for the provided unique_constraint name, and raises an
              # error if the unique_constraint does not exist
              def unique_constraint name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                raise UniqueConstraintDoesNotExistError unless has_unique_constraint? name
                @unique_constraints[name]
              end

              # returns true if this table has a unique_constraint with the provided name, otherwise false
              def has_unique_constraint? name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @unique_constraints.key? name
              end

              # returns an array of this tables unique_constraints
              def unique_constraints
                @unique_constraints.values
              end

              def unique_constraints_hash
                @unique_constraints
              end

              # adds a new unique_constraint to this table, and returns it
              def add_unique_constraint name, column_names, **unique_constraint_options
                if has_unique_constraint? name
                  raise(UniqueConstraintAlreadyExistsError, "unique_constraint #{name} already exists")
                end
                columns = column_names.map { |column_name| column column_name }
                included_target = self
                if included_target.is_a? Table
                  new_unique_constraint = @unique_constraints[name] = UniqueConstraint.new source, included_target, columns, name, **unique_constraint_options
                else
                  raise ModuleIncludedIntoUnexpectedTargetError, included_target
                end
                # sort the hash so that the unique_constraints are in alphabetical order by name
                sorted_unique_constraints = {}
                @unique_constraints.keys.sort.each do |name|
                  sorted_unique_constraints[name] = @unique_constraints[name]
                end
                @unique_constraints = sorted_unique_constraints
                # return the new unique_constraint
                new_unique_constraint
              end
            end
          end
        end
      end
    end
  end
end
