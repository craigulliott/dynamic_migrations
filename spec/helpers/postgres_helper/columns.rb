module Helpers
  class PostgresHelper
    module Columns
      def create_column schema_name, table_name, column_name, type
        # validate the type exists
        DynamicMigrations::Postgres::DataTypes.validate_type_exists! type
        # note the `type` is safe from sql_injection due to the validation above
        connection.exec(<<-SQL)
          ALTER TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s}
            ADD COLUMN #{connection.quote_ident column_name.to_s} #{type}
        SQL
        # refresh the cached representation of the database structure
        refresh_structure_cache_materialized_view
        # note that the database has been reset and there are no changes
        @has_changes = true
      end
    end
  end
end
