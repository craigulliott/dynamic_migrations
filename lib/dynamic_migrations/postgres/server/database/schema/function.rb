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

            class UnnormalizableDefinitionError < StandardError
            end

            attr_reader :schema
            attr_reader :name
            attr_reader :definition
            attr_reader :description
            attr_reader :triggers

            # initialize a new object to represent a postgres function
            def initialize source, schema, name, definition, description: nil
              super source

              @triggers = []

              raise ExpectedSchemaError, schema unless schema.is_a? Schema
              @schema = schema

              raise ExpectedSymbolError, name unless name.is_a? Symbol
              @name = name

              unless definition.is_a?(String) && definition.strip != "" && definition.strip.end_with?("END;", "END")
                raise ExpectedDefinitionError, "Definition must be a string, and end with `END;`. Definition provided:\n#{definition}"
              end
              @definition = definition.strip.freeze

              unless description.nil?
                raise ExpectedStringError, description unless description.is_a? String
                @description = description.strip.freeze
                @description = nil if description == ""
              end
            end

            # returns true if this function has a description, otehrwise false
            def has_description?
              !@description.nil?
            end

            # for tracking all the triggers which are associated with this function
            def add_trigger trigger
              # this should never happen, but adding it just in case
              unless trigger.source == source
                raise "Internal error - trigger source `#{trigger.source}` does not match function source `#{source}`"
              end
              @triggers << trigger
            end

            def differences_descriptions other_function
              method_differences_descriptions other_function, [
                :normalized_definition
              ]
            end

            # temporarily create a function in postgres and fetch the actual
            # normalized definition directly from the database
            def normalized_definition
              # no need to normalize definitions which originated from the database
              if from_database?
                definition
              else
                @normalized_definition ||= fetch_normalized_definition
              end
            end

            private

            def fetch_normalized_definition
              fn_def = schema.database.with_connection do |connection|
                # wrapped in a transaction just in case something here fails, because
                # we don't want the function to be persisted
                connection.exec("BEGIN")

                # create a temporary function, from which we will fetch the normalized definition
                connection.exec(<<~SQL)
                  CREATE OR REPLACE FUNCTION normalized_definition_temp_fn() returns trigger language plpgsql AS
                  $$#{definition}$$;
                SQL

                # get the normalzed version of the definition
                rows = connection.exec(<<~SQL)
                  SELECT prosrc AS function_definition
                  FROM pg_proc
                  WHERE proname = 'normalized_definition_temp_fn';
                SQL

                # delete the temp table and close the transaction
                connection.exec("ROLLBACK")

                # return the normalized function definition
                rows.first["function_definition"]
              end

              if fn_def.nil?
                raise UnnormalizableDefinitionError, "Failed to nomalize action condition `#{definition}`"
              end

              fn_def
            end
          end
        end
      end
    end
  end
end
