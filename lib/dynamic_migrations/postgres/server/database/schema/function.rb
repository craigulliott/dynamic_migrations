# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          # This class represents a postgres function.
          class Function < Source
            class ExpectedSchemaError < StandardError
            end

            class ExpectedDefinitionError < StandardError
            end

            attr_reader :schema
            attr_reader :name
            attr_reader :definition
            attr_reader :description
            attr_reader :triggers

            # initialize a new object to represent a postgres function
            def initialize source, schema, name, definition, description: nil
              super source

              @triggers ||= []

              raise ExpectedSchemaError, schema unless schema.is_a? Schema
              @schema = schema

              raise ExpectedSymbolError, name unless name.is_a? Symbol
              @name = name

              unless definition.is_a?(String) && definition.strip != ""
                raise ExpectedDefinitionError, definition
              end
              @definition = definition

              unless description.nil?
                raise ExpectedStringError, description unless description.is_a? String
                @description = description
              end
            end

            # returns true if this function has a description, otehrwise false
            def has_description?
              !@description.nil?
            end

            # returns all the triggers which are associated with this function
            def add_trigger trigger
              # this should never happen, but adding it just in case
              unless trigger.source == source
                raise "Internal error - trigger source `#{trigger.source}` does not match function source `#{source}`"
              end
              @triggers << trigger
            end

            def differences_descriptions other_function
              method_differences_descriptions other_function, [
                :definition
              ]
            end
          end
        end
      end
    end
  end
end
