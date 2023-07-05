module Helpers
  class PostgresHelper
    module Tables
      def create_table schema_name, table_name
        connection.exec(<<-SQL)
          CREATE TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s}(
            -- tables are created empty, and have columns added to them later
          );
        SQL
        # refresh the cached representation of the database structure
        refresh_structure_cache_materialized_view
        # note that the structure has changed, so that the database can be reset between tests
        @has_changes = true
      end

      def get_table_names schema_name
        rows = connection.exec_params(<<-SQL, [schema_name.to_s])
          SELECT table_name FROM information_schema.tables
            WHERE table_schema = $1
        SQL
        rows.map { |row| row["table_name"] }
      end

      def delete_tables schema_name
        get_table_names(schema_name).each do |table_name|
          connection.exec(<<-SQL)
            DROP TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s} CASCASE
          SQL
        end
      end
    end
  end
end
