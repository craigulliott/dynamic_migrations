# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { table.add_column :my_column, :boolean }
  let(:column2) { table.add_column :my_other_column, :boolean }
  let(:unique_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name }

  describe :initialize do
    it "instantiates a new unique_constraint without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name
      }.to_not raise_error
    end

    describe "providing an optional index_type value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name, index_type: :gist
        }.to_not raise_error
      end

      it "raises an error if providing an unexpected unique_constraint index_type" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name, index_type: :unexpected_index_type
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint::UnexpectedIndexTypeError
      end

      it "returns the expected value via a getter of the same name" do
        unique_constraint = DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name, index_type: :gist
        expect(unique_constraint.index_type).to be :gist
      end
    end

    describe "providing an optional deferrable value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name, deferrable: true
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        unique_constraint = DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name, deferrable: true
        expect(unique_constraint.deferrable).to be true
      end
    end

    describe "providing an optional initially_deferred value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name, initially_deferred: true
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        unique_constraint = DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name, initially_deferred: true
        expect(unique_constraint.initially_deferred).to be true
      end
    end

    it "raises an error if providing an invalid table" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, :not_a_table, [column], :unique_constraint_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint::ExpectedTableError
    end

    it "raises an error if providing something other than an array for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, :not_an_array, :unique_constraint_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing an array of objects which are not columns for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [:not_a_column], :unique_constraint_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing duplicate columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column, column], :unique_constraint_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint::DuplicateColumnError
    end

    it "raises an error if providing an empty array of columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [], :unique_constraint_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing something other than a symbol for the unique_constraint name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], "invalid unique_constraint name"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(unique_constraint.table).to eq(table)
    end
  end

  describe :columns do
    it "returns the expected columns" do
      expect(unique_constraint.columns).to eql([column])
    end
  end

  describe :column_names do
    it "returns the expected column_names" do
      expect(unique_constraint.column_names).to eql([:my_column])
    end
  end

  describe :unique_constraint_name do
    it "returns the expected unique_constraint_name" do
      expect(unique_constraint.unique_constraint_name).to eq(:unique_constraint_name)
    end
  end

  describe :index_type do
    it "returns the expected index_type" do
      expect(unique_constraint.index_type).to eq(:btree)
    end
  end

  describe :deferrable do
    it "returns the expected deferrable" do
      expect(unique_constraint.deferrable).to eq(false)
    end
  end

  describe :initially_deferred do
    it "returns the expected initially_deferred" do
      expect(unique_constraint.initially_deferred).to eq(false)
    end
  end
end
