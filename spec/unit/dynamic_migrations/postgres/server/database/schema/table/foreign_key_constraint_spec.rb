# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { schema.add_table :my_table }
  let(:column) { table.add_column :my_column, :boolean }
  let(:foreign_table) { schema.add_table :my_foreign_table }
  let(:foreign_column) { foreign_table.add_column :my_foreign_column, :boolean }
  let(:foreign_key_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column], :foreign_key_constraint_name }

  describe :initialize do
    it "instantiates a new foreign_key_constraint without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column], :foreign_key_constraint_name
      }.to_not raise_error
    end

    describe "providing an optional deferrable value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column], :foreign_key_constraint_name, deferrable: true
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        foreign_key_constraint = DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column], :foreign_key_constraint_name, deferrable: true
        expect(foreign_key_constraint.deferrable).to be true
      end
    end

    describe "providing an optional initially_deferred value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column], :foreign_key_constraint_name, initially_deferred: true
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        foreign_key_constraint = DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column], :foreign_key_constraint_name, initially_deferred: true
        expect(foreign_key_constraint.initially_deferred).to be true
      end
    end

    it "raises an error if the local and foreign table are the same" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], table, [column], :foreign_key_constraint_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedDifferentTablesError
    end

    describe "validating the local table and columns" do
      it "raises an error if providing an invalid table" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, :not_a_table, [column], foreign_table, [foreign_column], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedTableError
      end

      it "raises an error if providing something other than an array for columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, :not_an_array, foreign_table, [foreign_column], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedArrayOfColumnsError
      end

      it "raises an error if providing an array of objects which are not columns for columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [:not_a_column], foreign_table, [foreign_column], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedArrayOfColumnsError
      end

      it "raises an error if providing duplicate columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column, column], foreign_table, [foreign_column], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::DuplicateColumnError
      end

      it "raises an error if providing an empty array of columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [], foreign_table, [foreign_column], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedArrayOfColumnsError
      end

      it "raises an error if providing something other than a symbol for the foreign_key_constraint name" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column], "invalid foreign_key_constraint name"
        }.to raise_error DynamicMigrations::ExpectedSymbolError
      end
    end

    describe "validating the foreign table and columns" do
      it "raises an error if providing an invalid table" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], :not_a_table, [foreign_column], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedTableError
      end

      it "raises an error if providing something other than an array for columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, :not_an_array, :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedArrayOfColumnsError
      end

      it "raises an error if providing an array of objects which are not columns for columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [:not_a_column], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedArrayOfColumnsError
      end

      it "raises an error if providing duplicate columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column, foreign_column], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::DuplicateColumnError
      end

      it "raises an error if providing an empty array of columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [], :foreign_key_constraint_name
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint::ExpectedArrayOfColumnsError
      end

      it "raises an error if providing something other than a symbol for the foreign_key_constraint name" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint.new :configuration, table, [column], foreign_table, [foreign_column], "invalid foreign_key_constraint name"
        }.to raise_error DynamicMigrations::ExpectedSymbolError
      end
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(foreign_key_constraint.table).to eq(table)
    end
  end

  describe :columns do
    it "returns the expected columns" do
      expect(foreign_key_constraint.columns).to eql([column])
    end
  end

  describe :column_names do
    it "returns the expected columns" do
      expect(foreign_key_constraint.column_names).to eql([:my_column])
    end
  end

  describe :foreign_table do
    it "returns the expected foreign_table" do
      expect(foreign_key_constraint.foreign_table).to eq(foreign_table)
    end
  end

  describe :foreign_table_name do
    it "returns the expected foreign_table_name" do
      expect(foreign_key_constraint.foreign_table_name).to eq(:my_foreign_table)
    end
  end

  describe :foreign_schema_name do
    it "returns the expected foreign_schema_name" do
      expect(foreign_key_constraint.foreign_schema_name).to eq(:my_schema)
    end
  end

  describe :foreign_columns do
    it "returns the expected foreign_columns" do
      expect(foreign_key_constraint.foreign_columns).to eql([foreign_column])
    end
  end

  describe :foreign_column_names do
    it "returns the expected columns" do
      expect(foreign_key_constraint.foreign_column_names).to eql([:my_foreign_column])
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(foreign_key_constraint.name).to eq(:foreign_key_constraint_name)
    end
  end

  describe :deferrable do
    it "returns the expected deferrable" do
      expect(foreign_key_constraint.deferrable).to eq(false)
    end
  end

  describe :initially_deferred do
    it "returns the expected initially_deferred" do
      expect(foreign_key_constraint.initially_deferred).to eq(false)
    end
  end
end
