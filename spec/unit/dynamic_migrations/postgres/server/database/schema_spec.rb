# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }

  describe :initialize do
    it "instantiates a new schema without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema
      }.to_not raise_error
    end

    it "raises an error if providing an invalid source" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema.new :invalid, "not a database object", :my_schema
      }.to raise_error DynamicMigrations::InvalidSourceError
    end

    it "raises an error if providing an invalid database" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, "not a database object", :my_schema
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::ExpectedDatabaseError
    end

    it "raises an error if providing an invalid schema name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, "my_schema"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end
  end

  describe :database do
    it "returns the expected database" do
      expect(schema.database).to eq(database)
    end
  end

  describe :schema_name do
    it "returns the expected schema_name" do
      expect(schema.name).to eq(:my_schema)
    end
  end
end
