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
            raise MissingDatabaseNameError unless name
            raise AlreadyConnectedError if @connection
            @connection = Postgres::Connections.create_connection server.host, server.port, server.username, server.password, name
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

          # Opens a connection to the database server, and yields the provided block
          # before automatically closing the connection again. This is useful for
          # executing one time queries against the database server.
          def with_connection &block
            # create a temporary connection to the server
            connect
            # perform work with the connection
            # todo: `yield connection` would have been preferred, but rbs/steep doesnt understand that syntax
            if block.is_a? Proc
              result = block.call connection
            end
            # close the connection
            disconnect
            # return whever was returned from within the block
            result
          end
        end
      end
    end
  end
end
