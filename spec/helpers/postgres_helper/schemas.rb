module Helpers
  class PostgresHelper
    module Schemas
      # We assert there are no schemas before we run the test suite because it
      # requires starting with an empty database.
      #
      # We could clear it automatically here, but don't want to risk deleting data
      # in case the configuration is wrong and this is connected to an unexpected
      # database.
      def assert_no_schemas!
        get_schema_names.each do |schema_name|
          next if schema_name.start_with? "pg_"
          next if schema_name == "public"
          next if schema_name == "postgis"
          next if schema_name == "information_schema"
          raise "Expected no schemas to exist, but found #{schema_name} in #{@database} on #{@host}. Your test suite might have failed to complete the last time it was run. Please delete all schemas."
        end
      end

      def create_schema schema_name
        connection.exec(<<-SQL)
          CREATE SCHEMA #{connection.quote_ident schema_name.to_s};
        SQL
        # refresh the cached representation of the database structure
        refresh_structure_cache_materialized_view
        # note that the structure has changed, so that the database can be reset between tests
        @has_changes = true
      end

      def get_schema_names
        results = connection.exec(<<-SQL)
          SELECT schema_name
            FROM information_schema.schemata;
        SQL
        results.map { |row| row["schema_name"] }
      end

      def delete_all_schemas cascade: false
        get_schema_names.each do |schema_name|
          next if schema_name.start_with? "pg_"
          next if schema_name == "public"
          next if schema_name == "postgis"
          next if schema_name == "information_schema"
          connection.exec(<<-SQL)
            DROP SCHEMA #{connection.quote_ident schema_name.to_s} #{cascade ? "CASCADE" : ""};
          SQL
        end
        # refresh the cached representation of the database structure
        refresh_structure_cache_materialized_view
        # also refresh the constraints, as removing objects can affect them
        refresh_constraints_cache_materialized_view
        # note that the database has been reset and there are no changes
        @has_changes = true
      end
    end
  end
end
