module Helpers
  class PostgresHelper
    module Connection
      class ConnectionFailedError < StandardError
      end

      def connection
        @connection ||= PG.connect(
          host: @host,
          port: @port,
          user: @username,
          password: @password,
          dbname: @database,
          sslmode: "prefer"
        )
      end
    end
  end
end
