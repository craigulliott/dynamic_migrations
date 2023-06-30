# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { table.add_column :my_column, :boolean }
  let(:constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, table, [column], :constraint_name, "constraint SQL" }

  describe :initialize do
    it "instantiates a new constraint without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, table, [column], :constraint_name, "constraint SQL"
      }.to_not raise_error
    end

    it "raises an error if providing an invalid table" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, :not_a_table, [column], :constraint_name, "constraint SQL"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint::ExpectedTableError
    end

    it "raises an error if providing something other than an array for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, table, :not_an_array, :constraint_name, "constraint SQL"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing an array of objects which are not columns for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, table, [:not_a_column], :constraint_name, "constraint SQL"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing duplicate columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, table, [column, column], :constraint_name, "constraint SQL"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ColumnAlreadyExistsError
    end

    it "raises an error if providing an ampty array of columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, table, [], :constraint_name, "constraint SQL"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing something other than a symbol for the constraint name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, table, [column], "invalid constraint name", "constraint SQL"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    it "raises an error if providing something other than a string for the sql check_clause" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Constraint.new :configuration, table, [column], :constraint_name, :not_a_string
      }.to raise_error DynamicMigrations::ExpectedStringError
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(constraint.table).to eq(table)
    end
  end

  describe :columns do
    it "returns the expected columns" do
      expect(constraint.columns).to eql([column])
    end
  end

  describe :constraint_name do
    it "returns the expected constraint_name" do
      expect(constraint.constraint_name).to eq(:constraint_name)
    end
  end

  describe :check_clause do
    it "returns the expected check_clause" do
      expect(constraint.check_clause).to eq("constraint SQL")
    end
  end
end
