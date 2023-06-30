module Helpers
  class PostgresHelper
    module Connection
      class ConnectionFailedError < StandardError
      end

      def connection
        unless @connection
          @connection = PG.connect(
            host: @host,
            port: @port,
            user: @username,
            password: @password,
            dbname: @database,
            sslmode: "prefer"
          )
          # after initial connect, we refresh the cached representation of
          # the database structure and constaints
          refresh_structure_cache_materialized_view
          refresh_constraints_cache_materialized_view
        end
        @connection
      end
    end
  end
end
