# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::Column do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new schema, :my_table }
  let(:column) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new table, :my_column, :integer }

  describe :initialize do
    it "instantiates a new column without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new table, :my_column, :integer
      }.to_not raise_error
    end

    it "raises an error if providing an invalid schema" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new "not a schema object", :my_column, :integer
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Column::ExpectedTableError
    end

    it "raises an error if providing an invalid column name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new table, "my_column", :integer
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Column::ExpectedSymbolError
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(column.table).to eq(table)
    end
  end

  describe :column_name do
    it "returns the expected column_name" do
      expect(column.column_name).to eq(:my_column)
    end
  end
end
