# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new schema, :my_table }

  describe :initialize do
    it "instantiates a new table without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table.new schema, :my_table
      }.to_not raise_error
    end

    it "raises an error if providing an invalid schema" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table.new "not a schema object", :my_table
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ExpectedSchemaError
    end

    it "raises an error if providing an invalid table name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table.new schema, "my_table"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ExpectedSymbolError
    end
  end

  describe :schema do
    it "returns the expected schema" do
      expect(table.schema).to eq(schema)
    end
  end

  describe :table_name do
    it "returns the expected table_name" do
      expect(table.table_name).to eq(:my_table)
    end
  end
end
