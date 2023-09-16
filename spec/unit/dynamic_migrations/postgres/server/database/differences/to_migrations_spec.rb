# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }

  describe :initialize do
    it "instantiates a new differences without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences
      }.to_not raise_error
    end

    it "raises an error if providing an invalid database" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new "not a database object", differences
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::UnexpectedDatabaseObjectError
    end

    it "raises an error if providing an invalid differences" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, "not a differences object"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::UnexpectedDifferencesObjectError
    end
  end

  describe :migrations do
    # this is tested much more thoroughly via all the files in ./to_migrations/*
    it "returns no migrations because there are no differences" do
      expect(to_migrations.migrations).to eql([])
    end
  end
end
