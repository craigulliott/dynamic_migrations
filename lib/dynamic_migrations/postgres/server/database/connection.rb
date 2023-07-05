# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module Connection
          class NotConnectedError < StandardError
          end

          class MissingDatabaseNameError < StandardError
          end

          class AlreadyConnectedError < StandardError
          end

          def connect
            raise MissingDatabaseNameError unless database_name
            raise AlreadyConnectedError if @connection
            @connection = Postgres::Connections.create_connection server.host, server.port, server.username, server.password, database_name
          end

          def connection
            @connection || raise(NotConnectedError)
          end

          def disconnect
            if (conn = @connection)
              Postgres::Connections.disconnect conn
              @connection = nil
            else
              raise NotConnectedError
            end
          end
        end
      end
    end
  end
end
