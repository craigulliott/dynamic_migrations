# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Source
          attr_reader :source

          # initialize a new object to represent a postgres schema
          def initialize source
            unless source == :configuration || source == :database
              raise InvalidSourceError, source
            end
            @source = source
          end

          def from_configuration?
            @source == :configuration
          end

          def from_database?
            @source == :database
          end

          def assert_is_a_symbol! value
            if value.is_a? Symbol
              true
            else
              raise ExpectedSymbolError, "expected Symbol but got #{value}"
            end
          end

          private

          # used to compare two objects and return a description of the differences
          # it calls the method names provided on each object and compares the results
          # and returns a human readable description of the differences
          def method_differences_descriptions other_object, method_names
            lines = []
            ([:name] + method_names + [:description]).each do |method_name|
              original_value = send method_name
              updated_value = other_object.send method_name
              if original_value != updated_value
                lines << "#{method_name} changed from `#{original_value}` to `#{updated_value}`"
              end
            end

            # return an array of lines, not a finalized string, this is because this
            # method is typically called as part of a larger procedure that will compare
            # other aspects of the object too
            lines
          end
        end
      end
    end
  end
end
