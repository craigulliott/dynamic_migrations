# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :Connection do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :connect do
      it "connects to the database without error" do
        expect {
          database.connect
        }.to_not raise_error
      end

      it "creates a working connection" do
        connection = database.connect
        results = connection.exec("select 1 as test")
        expect(results[0]["test"]).to eq("1")
      end

      it "places the connection in the global connection pool" do
        connection = database.connect
        expect(DynamicMigrations::Postgres::Connections.connections).to eql [connection]
      end
    end

    describe :connection do
      it "raises an error" do
        expect {
          database.connection
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        let(:connection) { database.connect }

        before :each do
          connection
        end

        it "returns the expected connection" do
          expect(database.connection).to eq(connection)
        end

        it "returns a working connection" do
          results = connection.exec("select 1 as test")
          expect(results[0]["test"]).to eq("1")
        end
      end
    end

    describe :disconnect do
      it "raises an error" do
        expect {
          database.disconnect
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "removes the connection from the global connection pool" do
          database.disconnect
          expect(DynamicMigrations::Postgres::Connections.connections).to eql []
        end

        it "removes the connection from database object" do
          database.disconnect
          expect {
            database.connection
          }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
        end
      end
    end
  end
end
