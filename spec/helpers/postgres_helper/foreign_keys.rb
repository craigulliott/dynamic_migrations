module Helpers
  class PostgresHelper
    module ForeignKeys
      def create_foreign_key schema_name, table_name, column_names, foreign_schema_name, foreign_table_name, foreign_column_names, foreign_key_name
        column_names_sql = column_names.map { |n| connection.quote_ident n.to_s }.join(", ")
        foreign_column_names_sql = column_names.map { |n| connection.quote_ident n.to_s }.join(", ")
        # add the foreign key
        connection.exec(<<-SQL)
          ALTER TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s}
            ADD CONSTRAINT #{connection.quote_ident foreign_key_name.to_s}
            FOREIGN KEY (#{column_names_sql})
              REFERENCES #{connection.quote_ident foreign_schema_name.to_s}.#{connection.quote_ident foreign_table_name.to_s} (#{foreign_column_names_sql})
        SQL
        # refresh the cached representation of the database foreign keys
        refresh_keys_and_unique_constraints_cache_materialized_view
        # note that the database has been reset and there are no changes
        @has_changes = true
      end
    end
  end
end
