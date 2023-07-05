module Helpers
  class PostgresHelper
    module UniqueConstraints
      # add a unique constraint to the provided table and columns
      def add_unique_constraint schema_name, table_name, column_names, constraint_key_name
        column_names_sql = column_names.map{|n| connection.quote_ident n.to_s}.join(', ')
        # add the constraint key
        connection.exec(<<-SQL)
          ALTER TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s}
            ADD CONSTRAINT #{connection.quote_ident constraint_key_name.to_s}
            UNIQUE (#{column_names_sql})
        SQL
        # refresh the cached representation of the database constraint keys
        refresh_keys_and_unique_constraints_cache_materialized_view
        # note that the database has been reset and there are no changes
        @has_changes = true
      end
    end
  end
end
