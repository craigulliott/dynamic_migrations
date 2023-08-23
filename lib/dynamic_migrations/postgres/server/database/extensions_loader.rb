# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module ExtensionsLoader
          # return an array of the extensions active in this database
          def fetch_extensions
            rows = connection.exec(<<~SQL)
              SELECT
                extname AS name
              FROM pg_extension;
            SQL

            extensions = []
            rows.each do |row|
              extensions << row["name"].to_sym
            end
            extensions
          end
        end
      end
    end
  end
end
