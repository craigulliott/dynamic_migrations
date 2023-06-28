module Helpers
  class PostgresHelper
    module Tables
      def create_table schema_name, table_name
        connection.exec(<<-SQL)
          CREATE TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s}(
            -- tables are created empty, and have columns added to them later
          );
        SQL
      end

      def get_table_names
        rows = database.connection.exec_params(<<-SQL, [schema_name])
          SELECT table_name FROM information_schema.tables
            WHERE table_schema = $1
        SQL
        rows.map { |row| row["table_name"] }
      end
    end
  end
end
