module Helpers
  class PostgresHelper
    module IndexCache
      # whenever schema changes are made from within the test suite we need to
      # rebuild the materialized views that hold a cached representation of the
      # database indexes
      def refresh_index_cache_materialized_view
        # the first time we detect the presence of the marerialized view, we no longer need to
        # check for it
        @index_cache_exists ||= index_cache_exists?
        if @index_cache_exists
          connection.exec(<<~SQL)
            REFRESH MATERIALIZED VIEW public.dynamic_migrations_index_cache;
          SQL
        end
      end

      def index_cache_exists?
        exists = connection.exec(<<~SQL)
          SELECT TRUE AS exists FROM pg_matviews WHERE schemaname = 'public' AND matviewname = 'dynamic_migrations_index_cache';
        SQL
        exists.count > 0
      end
    end
  end
end
