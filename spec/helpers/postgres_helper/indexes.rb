module Helpers
  class PostgresHelper
    module Indexes
      def create_index schema_name, table_name, column_names, index_name, type, deferrable, initially_deferred
        connection.exec(<<-SQL)
          CREATE INDEX #{connection.quote_ident index_name.to_s}
            ON #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s} (b, c)
        SQL
        # refresh the cached representation of the database indexes
        refresh_index_cache_materialized_view
        # note that the database has been reset and there are no changes
        @has_changes = true
      end
    end
  end
end
