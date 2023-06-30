# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::Column do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean }

  describe :initialize do
    it "instantiates a new column without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean
      }.to_not raise_error
    end

    it "raises an error if providing an invalid schema" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, "not a schema object", :my_column, :boolean
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Column::ExpectedTableError
    end

    it "raises an error if providing an invalid column name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, "my_column", :integer
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    describe "when providing an optional description" do
      it "instantiates a new column without raising an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean, description: "a valid description of my table"
        }.to_not raise_error
      end

      it "raises an error if providing an invalid schema" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean, description: :an_invalid_description_type
        }.to raise_error DynamicMigrations::ExpectedStringError
      end
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

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(column.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:column_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean, description: "a valid description of my column" }
      it "returns the expected description" do
        expect(column_with_description.description).to eq("a valid description of my column")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(column.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:column_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean, description: "a valid description of my column" }
      it "returns true" do
        expect(column_with_description.has_description?).to be(true)
      end
    end
  end
end
