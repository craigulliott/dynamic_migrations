# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          # This class represents a postgres enum.
          class Enum < Source
            class ExpectedSchemaError < StandardError
            end

            class ExpectedValuesError < StandardError
            end

            attr_reader :schema
            attr_reader :name
            attr_reader :values
            attr_reader :description

            # initialize a new object to represent a postgres enum
            def initialize source, schema, name, values, description: nil
              super source

              @values = []

              raise ExpectedSchemaError, schema unless schema.is_a? Schema
              @schema = schema

              raise ExpectedSymbolError, name unless name.is_a? Symbol
              @name = name

              unless values.is_a?(Array) && values.count > 0
                raise ExpectedValuesError, "Values are required for enums"
              end
              @values = values

              unless description.nil?
                raise ExpectedStringError, description unless description.is_a? String
                @description = description.strip
                @description = nil if description == ""
              end
            end

            # returns true if this enum has a description, otehrwise false
            def has_description?
              !@description.nil?
            end

            def differences_descriptions other_enum
              method_differences_descriptions other_enum, [
                :values
              ]
            end

            def full_name
              :"#{schema.name}.#{name}"
            end
          end
        end
      end
    end
  end
end
