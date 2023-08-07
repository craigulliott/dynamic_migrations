# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        # This class represents a postgres schema. A schema is essentially a namespace within
        # a postgres database. Each schema is a collection of tables, functions and other
        # database objects.
        class Schema < Source
          class ExpectedDatabaseError < StandardError
          end

          include Tables
          include Functions

          attr_reader :database
          attr_reader :name

          # initialize a new object to represent a postgres schema
          def initialize source, database, name
            super source
            raise ExpectedDatabaseError, database unless database.is_a? Database
            raise ExpectedSymbolError, name unless name.is_a? Symbol
            @database = database
            @name = name
            @tables = {}
            @functions = {}
          end
        end
      end
    end
  end
end
