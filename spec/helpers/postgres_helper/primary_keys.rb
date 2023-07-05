module Helpers
  class PostgresHelper
    module PrimaryKeys
      # add a primary_key to the provided table which covers the provided columns
      def add_primary_key schema_name, table_name, column_names
        column_names_sql = column_names.map { |n| connection.quote_ident n.to_s }.join(", ")
        # add the primary_key
        connection.exec(<<-SQL)
          ALTER TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s}
            ADD PRIMARY KEY (#{column_names_sql})
        SQL
        # refresh the cached representation of the database primary_key keys
        refresh_keys_and_unique_constraints_cache_materialized_view
        # note that the database has been reset and there are no changes
        @has_changes = true
      end
    end
  end
end
