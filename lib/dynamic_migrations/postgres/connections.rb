# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    module Connections
      @connections = {}

      def self.create_connection host, port, username, password, database
        connection = PG.connect(
          host: host,
          port: port,
          user: username,
          password: password,
          dbname: database,
          sslmode: "prefer"
        )
        @connections[connection] = true
        connection
      end

      def self.connections
        @connections.keys
      end

      def self.disconnect connection
        if @connections[connection]
          connection.close
          @connections.delete connection
          true
        else
          false
        end
      end

      def self.disconnect_all
        @connections.keys.each do |connection|
          disconnect connection
        end
      end
    end
  end
end
