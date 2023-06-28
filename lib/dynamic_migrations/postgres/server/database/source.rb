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
        end
      end
    end
  end
end
