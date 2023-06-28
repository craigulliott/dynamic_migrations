# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema do
  describe :ConfiguredTables do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new database, :my_schema }

    describe :add_table_from_configuration do
      it "creates a new table object" do
        expect(schema.add_table_from_configuration(:table_name)).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table
      end

      it "raises an error if providing an invalid table name" do
        expect {
          schema.add_table_from_configuration "table_name"
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::ExpectedSymbolError
      end

      describe "when a table already exists" do
        before(:each) do
          schema.add_table_from_configuration(:table_name)
        end

        it "raises an error if using the same table name" do
          expect {
            schema.add_table_from_configuration(:table_name)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::ConfiguredTableAlreadyExistsError
        end
      end
    end

    describe :configured_table do
      it "returns nil" do
        expect(schema.configured_table(:table_name)).to be_nil
      end

      describe "after the expected table has been added" do
        let(:table) { schema.add_table_from_configuration :table_name }

        before(:each) do
          table
        end

        it "returns the table" do
          expect(schema.configured_table(:table_name)).to eq(table)
        end
      end
    end

    describe :configured_tables do
      it "returns an empty array" do
        expect(schema.configured_tables).to be_an Array
        expect(schema.configured_tables).to be_empty
      end

      describe "after the expected table has been added" do
        let(:table) { schema.add_table_from_configuration :table_name }

        before(:each) do
          table
        end

        it "returns an array of the expected tables" do
          expect(schema.configured_tables).to eql([table])
        end
      end
    end
  end
end
