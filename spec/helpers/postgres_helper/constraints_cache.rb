module Helpers
  class PostgresHelper
    module ConstraintsCache
      # whenever schema changes are made from within the test suite we need to
      # rebuild the materialized views that hold a cached representation of the
      # database structure
      def refresh_constraints_cache_materialized_view
        # the first time we detect the presence of the marerialized view, we no longer need to
        # check for it
        @constraints_cache_exists ||= constraints_cache_exists?
        if @constraints_cache_exists
          connection.exec(<<~SQL)
            REFRESH MATERIALIZED VIEW public.dynamic_migrations_constraints_cache;
          SQL
        end
      end

      def constraints_cache_exists?
        exists = connection.exec(<<~SQL)
          SELECT TRUE AS exists FROM pg_matviews WHERE schemaname = 'public' AND matviewname = 'dynamic_migrations_constraints_cache';
        SQL
        exists.count > 0
      end
    end
  end
end
