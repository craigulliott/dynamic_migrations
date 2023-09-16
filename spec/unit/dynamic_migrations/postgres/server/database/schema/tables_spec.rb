# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }

  describe :Tables do
    describe :add_table do
      it "creates a new table object" do
        expect(schema.add_table(:table_name)).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table
      end

      it "raises an error if providing an invalid table name" do
        expect {
          schema.add_table "table_name"
        }.to raise_error DynamicMigrations::ExpectedSymbolError
      end

      describe "when a table already exists" do
        before(:each) do
          schema.add_table(:table_name)
        end

        it "raises an error if using the same table name" do
          expect {
            schema.add_table(:table_name)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::TableAlreadyExistsError
        end
      end
    end

    describe :table do
      it "raises an error" do
        expect {
          schema.table(:table_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::TableDoesNotExistError
      end

      describe "after the expected table has been added" do
        let(:table) { schema.add_table :table_name }

        before(:each) do
          table
        end

        it "returns the table" do
          expect(schema.table(:table_name)).to eq(table)
        end
      end
    end

    describe :has_table? do
      it "returns false" do
        expect(schema.has_table?(:table_name)).to be(false)
      end

      describe "after the expected table has been added" do
        let(:table) { schema.add_table :table_name }

        before(:each) do
          table
        end

        it "returns true" do
          expect(schema.has_table?(:table_name)).to be(true)
        end
      end
    end

    describe :tables do
      it "returns an empty array" do
        expect(schema.tables).to be_an Array
        expect(schema.tables).to be_empty
      end

      describe "after the expected table has been added" do
        let(:table) { schema.add_table :table_name }

        before(:each) do
          table
        end

        it "returns an array of the expected tables" do
          expect(schema.tables).to eql([table])
        end
      end
    end

    describe :tables_hash do
      it "returns an empty hash" do
        expect(schema.tables_hash).to eql({})
      end

      describe "after the expected table has been added" do
        let(:table) { schema.add_table :table_name }

        before(:each) do
          table
        end

        it "returns a hash representation of the expected tables" do
          expect(schema.tables_hash).to eql({table_name: table})
        end
      end
    end
  end
end
