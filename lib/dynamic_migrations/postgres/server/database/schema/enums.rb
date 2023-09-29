# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema < Source
          module Enums
            class EnumAlreadyExistsError < StandardError
            end

            class EnumDoesNotExistError < StandardError
            end

            # create and add a new enum
            def add_enum enum_name, values, description: nil
              raise ExpectedSymbolError, enum_name unless enum_name.is_a? Symbol
              if has_enum? enum_name
                raise(EnumAlreadyExistsError, "Enum #{enum_name} already exists")
              end
              included_target = self
              if included_target.is_a? Schema
                new_enum = @enums[enum_name] = Enum.new source, included_target, enum_name, values, description: description
              else
                raise ModuleIncludedIntoUnexpectedTargetError, included_target
              end
              # sort the hash so that the enums are in alphabetical order by name
              sorted_enums = {}
              @enums.keys.sort.each do |enum_name|
                sorted_enums[enum_name] = @enums[enum_name]
              end
              @enums = sorted_enums
              # return the new enum
              new_enum
            end

            # return a enum by its name, raises an error if the enum does not exist
            def enum enum_name
              raise ExpectedSymbolError, enum_name unless enum_name.is_a? Symbol
              unless has_enum? enum_name
                raise EnumDoesNotExistError, "Enum `#{enum_name}` does not exist"
              end
              @enums[enum_name]
            end

            # returns true/false representing if a enum with the provided name exists
            def has_enum? enum_name
              raise ExpectedSymbolError, enum_name unless enum_name.is_a? Symbol
              @enums.key? enum_name
            end

            # returns an array of all enums in the schema
            def enums
              @enums.values
            end

            def enums_hash
              @enums
            end
          end
        end
      end
    end
  end
end
