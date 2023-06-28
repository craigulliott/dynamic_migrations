# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }

  describe :initialize do
    it "instantiates a new database without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database.new server, :my_database
      }.to_not raise_error
    end

    it "raises an error if providing an invalid server" do
      expect {
        DynamicMigrations::Postgres::Server::Database.new "not a server object", :my_database
      }.to raise_error DynamicMigrations::Postgres::Server::Database::ExpectedServerError
    end

    it "raises an error if providing an invalid database name" do
      expect {
        DynamicMigrations::Postgres::Server::Database.new server, "my_database"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::ExpectedSymbolError
    end
  end

  describe :server do
    it "returns the expected server" do
      expect(database.server).to eq(server)
    end
  end

  describe :database_name do
    it "returns the expected database_name" do
      expect(database.database_name).to eq(:my_database)
    end
  end
end
