# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { table.add_column :my_column, :boolean }
  let(:column2) { table.add_column :my_other_column, :boolean }
  let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name }

  describe :initialize do
    it "instantiates a new index without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name
      }.to_not raise_error
    end

    describe "providing an optional index_type value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name, index_type: :gin
        }.to_not raise_error
      end

      it "raises an error if providing an unexpected index index_type" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name, index_type: :unexpected_index_type
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey::UnexpectedIndexTypeError
      end

      it "returns the expected value via a getter of the same name" do
        index = DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name, index_type: :gin
        expect(index.index_type).to be :gin
      end
    end

    it "raises an error if providing an invalid table" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, :not_a_table, [column], :primary_key_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey::ExpectedTableError
    end

    it "raises an error if providing something other than an array for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, :not_an_array, :primary_key_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing an array of objects which are not columns for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [:not_a_column], :primary_key_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing duplicate columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column, column], :primary_key_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey::DuplicateColumnError
    end

    it "raises an error if providing an empty array of columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [], :primary_key_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing something other than a symbol for the index name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], "invalid index name"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(index.table).to eq(table)
    end
  end

  describe :columns do
    it "returns the expected columns" do
      expect(index.columns).to eql([column])
    end
  end

  describe :primary_key_name do
    it "returns the expected primary_key_name" do
      expect(index.primary_key_name).to eq(:primary_key_name)
    end
  end

  describe :index_type do
    it "returns the expected index_type" do
      expect(index.index_type).to eq(:btree)
    end
  end
end
