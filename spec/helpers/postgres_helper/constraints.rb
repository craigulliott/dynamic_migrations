module Helpers
  class PostgresHelper
    module Constraints
      def create_constraint schema_name, table_name, constraint_name, check_clause
        # todo the check_clause is vilnerable to sql injection (although this is very low risk because
        #      it is only ever provided by the test suite, and is never provided by the user)
        connection.exec(<<-SQL)
          ALTER TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s}
            ADD CONSTRAINT #{connection.quote_ident constraint_name.to_s} CHECK (#{check_clause})
        SQL
        # refresh the cached representation of the database structure
        refresh_constraints_cache_materialized_view
        # note that the database has been reset and there are no changes
        @has_changes = true
      end
    end
  end
end
