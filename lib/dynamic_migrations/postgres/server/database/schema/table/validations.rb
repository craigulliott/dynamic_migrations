# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table < Source
            # This module has all the tables methods for working with validations
            module Validations
              class ValidationDoesNotExistError < StandardError
              end

              class ValidationAlreadyExistsError < StandardError
              end

              # returns the validation object for the provided validation name, and raises an
              # error if the validation does not exist
              def validation name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                raise ValidationDoesNotExistError unless has_validation? name
                @validations[name]
              end

              # returns true if this table has a validation with the provided name, otherwise false
              def has_validation? name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @validations.key? name
              end

              # returns an array of this tables validations
              def validations
                @validations.values
              end

              def validations_hash
                @validations
              end

              # adds a new validation to this table, and returns it
              def add_validation name, column_names, check_clause, **validation_options
                if has_validation? name
                  raise(ValidationAlreadyExistsError, "Validation #{name} already exists")
                end
                columns = column_names&.map { |column_name| column column_name }
                included_target = self
                if included_target.is_a? Table
                  new_validation = @validations[name] = Validation.new source, included_target, columns, name, check_clause, **validation_options
                else
                  raise ModuleIncludedIntoUnexpectedTargetError, included_target
                end
                # sort the hash so that the validations are in alphabetical order by name
                sorted_validations = {}
                @validations.keys.sort.each do |name|
                  sorted_validations[name] = @validations[name]
                end
                @validations = sorted_validations
                # return the new validation
                new_validation
              end
            end
          end
        end
      end
    end
  end
end
