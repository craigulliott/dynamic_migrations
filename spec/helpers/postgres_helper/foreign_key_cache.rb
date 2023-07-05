module Helpers
  class PostgresHelper
    module ForeignKeyCache
      # whenever schema changes are made from within the test suite we need to
      # rebuild the materialized views that hold a cached representation of the
      # database foreign keys
      def refresh_keys_and_unique_constraints_cache_materialized_view
        # the first time we detect the presence of the marerialized view, we no longer need to
        # check for it
        @keys_and_unique_constraints_cache_exists ||= keys_and_unique_constraints_cache_exists?
        if @keys_and_unique_constraints_cache_exists
          connection.exec(<<~SQL)
            REFRESH MATERIALIZED VIEW public.dynamic_migrations_keys_and_unique_constraints_cache;
          SQL
        end
      end

      def keys_and_unique_constraints_cache_exists?
        exists = connection.exec(<<~SQL)
          SELECT TRUE AS exists FROM pg_matviews WHERE schemaname = 'public' AND matviewname = 'dynamic_migrations_keys_and_unique_constraints_cache';
        SQL
        exists.count > 0
      end
    end
  end
end
