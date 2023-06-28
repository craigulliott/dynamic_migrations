# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema do
  describe :LoadedTables do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new database, :my_schema }

    describe :add_table_from_database do
      it "creates a new table object" do
        expect(schema.add_table_from_database(:table_name)).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table
      end

      it "raises an error if providing an invalid table name" do
        expect {
          schema.add_table_from_database "my_database"
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::ExpectedSymbolError
      end

      describe "when a table already exists" do
        before(:each) do
          schema.add_table_from_database(:table_name)
        end

        it "raises an error if using the same table name" do
          expect {
            schema.add_table_from_database(:table_name)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::LoadedTableAlreadyExistsError
        end
      end
    end

    describe :loaded_table do
      it "returns nil" do
        expect(schema.loaded_table(:table_name)).to be_nil
      end

      describe "after the expected table has been added" do
        let(:table) { schema.add_table_from_database :table_name }

        before(:each) do
          table
        end

        it "returns the table" do
          expect(schema.loaded_table(:table_name)).to eq(table)
        end
      end
    end

    describe :loaded_tables do
      it "returns an empty array" do
        expect(schema.loaded_tables).to be_an Array
        expect(schema.loaded_tables).to be_empty
      end

      describe "after the expected table has been added" do
        let(:table) { schema.add_table_from_database :table_name }

        before(:each) do
          table
        end

        it "returns an array of the expected tables" do
          expect(schema.loaded_tables).to eql([table])
        end
      end
    end

    describe :fetch_table_names do
      it "raises an error" do
        expect {
          schema.fetch_table_names
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          schema.database.connect
        end

        it "returns an empty array" do
          expect(schema.fetch_table_names).to be_empty
        end

        describe "after a table has been added" do
          before :each do
            pg_helper.create_schema :my_schema
            pg_helper.create_table :my_schema, :foo
          end

          it "returns the expected array" do
            expect(schema.fetch_table_names).to eql ["foo"]
          end
        end
      end
    end

    describe :load_tables do
      it "raises an error" do
        expect {
          schema.load_tables
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          schema.database.connect
        end

        it "does not raise an error" do
          expect {
            schema.load_tables
          }.to_not raise_error
        end

        it "does not add any tables to the database object" do
          schema.load_tables
          expect(schema.loaded_tables).to be_empty
        end

        describe "after a table has been added" do
          before :each do
            pg_helper.create_schema :my_schema
            pg_helper.create_table :my_schema, :foo
          end

          it "does add a tables to the database object" do
            schema.load_tables
            expect(schema.loaded_tables.count).to eq(1)
            expect(schema.loaded_tables.first.table_name).to eq(:foo)
          end
        end
      end
    end
  end
end
