# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Connections do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:connections_module) { DynamicMigrations::Postgres::Connections }
  let(:connection) { connections_module.create_connection(pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password, pg_helper.database) }
  let(:connection2) { connections_module.create_connection(pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password, pg_helper.database) }

  describe :create_connection do
    it "creates and returns a new connection" do
      expect(connections_module.create_connection(pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password, pg_helper.database)).to be_a PG::Connection
    end
  end

  describe :connections do
    it "returns an empty array" do
      expect(connections_module.connections).to be_a Array
      expect(connections_module.connections).to be_empty
    end

    describe "after a connection has been added" do
      before(:each) {
        connection
      }

      it "returns an array of the expected connections" do
        expect(connections_module.connections).to be_a Array
        expect(connections_module.connections).to eql [connection]
      end

      describe "after another connection has been added" do
        before(:each) {
          connection2
        }

        it "returns an array of the expected connections" do
          expect(connections_module.connections).to be_a Array
          expect(connections_module.connections).to eql [connection, connection2]
        end
      end
    end
  end

  describe :disconnect do
    before(:each) {
      connection
    }

    it "disconnects a provided connection" do
      # has a connection
      expect(connections_module.connections).to eql [connection]
      # successfully disconnects the connection
      expect(connections_module.disconnect(connection)).to be true
      # there are no longer any connections
      expect(connections_module.connections).to be_empty
    end

    it "returns false if the connection doesnt exist" do
      # disconnect the connection
      connections_module.disconnect(connection)
      # try to disconnect it again, and expect to receive false
      expect(connections_module.disconnect(connection)).to be false
    end
  end

  describe :disconnect_all do
    it "does not error if there are no connections" do
      expect {
        connections_module.disconnect_all
      }.to_not raise_error
    end

    describe "after creating a connection" do
      before(:each) {
        connection
      }

      it "disconnects all the connections" do
        # has a connection
        expect(connections_module.connections).to eql [connection]
        # successfully disconnects the connection
        connections_module.disconnect_all
        # there are no longer any connections
        expect(connections_module.connections).to be_empty
      end
    end
  end
end
