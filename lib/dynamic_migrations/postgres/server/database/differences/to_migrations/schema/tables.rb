# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Differences
          class ToMigrations
            module Schemas
              module Tables
                def process_tables schema_name, configuration_tables, database_tables
                end
              end
            end
          end
        end
      end
    end
  end
end
