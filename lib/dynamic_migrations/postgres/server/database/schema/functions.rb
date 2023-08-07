# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema < Source
          module Functions
            class FunctionAlreadyExistsError < StandardError
            end

            class FunctionDoesNotExistError < StandardError
            end

            # create and add a new function from a provided function name
            def add_function function_name, definition, description: nil
              raise ExpectedSymbolError, function_name unless function_name.is_a? Symbol
              if has_function? function_name
                raise(FunctionAlreadyExistsError, "Function #{function_name} already exists")
              end
              included_target = self
              if included_target.is_a? Schema
                new_function = @functions[function_name] = Function.new source, included_target, function_name, definition, description: description
              else
                raise ModuleIncludedIntoUnexpectedTargetError, included_target
              end
              # sort the hash so that the functions are in alphabetical order by name
              sorted_functions = {}
              @functions.keys.sort.each do |function_name|
                sorted_functions[function_name] = @functions[function_name]
              end
              @functions = sorted_functions
              # return the new function
              new_function
            end

            # return a function by its name, raises an error if the function does not exist
            def function function_name
              raise ExpectedSymbolError, function_name unless function_name.is_a? Symbol
              raise FunctionDoesNotExistError unless has_function? function_name
              @functions[function_name]
            end

            # returns true/false representing if a function with the provided name exists
            def has_function? function_name
              raise ExpectedSymbolError, function_name unless function_name.is_a? Symbol
              @functions.key? function_name
            end

            # returns an array of all functions in the schema
            def functions
              @functions.values
            end

            def functions_hash
              @functions
            end
          end
        end
      end
    end
  end
end
