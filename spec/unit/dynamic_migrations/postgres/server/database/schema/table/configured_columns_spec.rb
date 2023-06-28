# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  describe :ConfiguredColumns do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new schema, :my_table }

    describe :add_column_from_configuration do
      it "creates a new column object" do
        expect(table.add_column_from_configuration(:column_name, :integer)).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::Column
      end

      it "raises an error if providing an invalid column name" do
        expect {
          table.add_column_from_configuration "my_column", :integer
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ExpectedSymbolError
      end

      describe "when a column already exists" do
        before(:each) do
          table.add_column_from_configuration(:column_name, :integer)
        end

        it "raises an error if using the same column name" do
          expect {
            table.add_column_from_configuration(:column_name, :integer)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ConfiguredColumnAlreadyExistsError
        end
      end
    end

    describe :configured_column do
      it "returns nil" do
        expect(table.configured_column(:column_name)).to be_nil
      end

      describe "after the expected column has been added" do
        let(:column) { table.add_column_from_configuration :column_name, :integer }

        before(:each) do
          column
        end

        it "returns the column" do
          expect(table.configured_column(:column_name)).to eq(column)
        end
      end
    end

    describe :configured_columns do
      it "returns an empty array" do
        expect(table.configured_columns).to be_an Array
        expect(table.configured_columns).to be_empty
      end

      describe "after the expected column has been added" do
        let(:column) { table.add_column_from_configuration :column_name, :integer }

        before(:each) do
          column
        end

        it "returns an array of the expected columns" do
          expect(table.configured_columns).to eql([column])
        end
      end
    end
  end
end
