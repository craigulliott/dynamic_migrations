# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { table.add_column :my_column, :boolean }
  let(:column2) { table.add_column :my_other_column, :boolean }
  let(:primary_key) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name }

  describe :initialize do
    it "instantiates a new primary_key without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name
      }.to_not raise_error
    end

    describe "providing an optional description" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name, description: "foo bar"
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        primary_key = DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name, description: "foo bar"
        expect(primary_key.description).to be "foo bar"
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

    it "raises an error if providing something other than a symbol for the primary_key name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], "invalid index name"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(primary_key.table).to eq(table)
    end
  end

  describe :columns do
    it "returns the expected columns" do
      expect(primary_key.columns).to eql([column])
    end
  end

  describe :column_names do
    it "returns the expected columns" do
      expect(primary_key.column_names).to eql([:my_column])
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(primary_key.name).to eq(:primary_key_name)
    end
  end

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(primary_key.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:primary_key_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name, description: "foo bar" }
      it "returns the expected description" do
        expect(primary_key_with_description.description).to eq("foo bar")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(primary_key.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:primary_key_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name, description: "foo bar" }
      it "returns true" do
        expect(primary_key_with_description.has_description?).to be(true)
      end
    end
  end

  describe :differences_descriptions do
    describe "when compared to a primary_key which has different columns" do
      let(:different_primary_key) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column, column2], :primary_key_name }

      it "returns the expected array which describes the differences" do
        expect(primary_key.differences_descriptions(different_primary_key)).to eql([
          "column_names changed from `[:my_column]` to `[:my_column, :my_other_column]`"
        ])
      end
    end
  end
end
