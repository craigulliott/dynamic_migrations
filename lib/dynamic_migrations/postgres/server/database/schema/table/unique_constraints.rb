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
              def unique_constraint unique_constraint_name
                raise ExpectedSymbolError, unique_constraint_name unless unique_constraint_name.is_a? Symbol
                raise UniqueConstraintDoesNotExistError unless has_unique_constraint? unique_constraint_name
                @unique_constraints[unique_constraint_name]
              end

              # returns true if this table has a unique_constraint with the provided name, otherwise false
              def has_unique_constraint? unique_constraint_name
                raise ExpectedSymbolError, unique_constraint_name unless unique_constraint_name.is_a? Symbol
                @unique_constraints.key? unique_constraint_name
              end

              # returns an array of this tables unique_constraints
              def unique_constraints
                @unique_constraints.values
              end

              def unique_constraints_hash
                @unique_constraints
              end

              # adds a new unique_constraint to this table, and returns it
              def add_unique_constraint unique_constraint_name, column_names, **unique_constraint_options
                if has_unique_constraint? unique_constraint_name
                  raise(UniqueConstraintAlreadyExistsError, "unique_constraint #{unique_constraint_name} already exists")
                end
                columns = column_names.map { |column_name| column column_name }
                @unique_constraints[unique_constraint_name] = UniqueConstraint.new source, self, columns, unique_constraint_name, **unique_constraint_options
              end
            end
          end
        end
      end
    end
  end
end
