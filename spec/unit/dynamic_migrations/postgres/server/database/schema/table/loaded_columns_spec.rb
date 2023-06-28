# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema do
  describe :LoadedTables do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new schema, :my_table }

    describe :add_column_from_database do
      it "creates a new column object" do
        expect(table.add_column_from_database(:column_name, :integer)).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::Column
      end

      it "raises an error if providing an invalid column name" do
        expect {
          table.add_column_from_database "my_database", :integer
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ExpectedSymbolError
      end

      describe "when a column already exists" do
        before(:each) do
          table.add_column_from_database(:column_name, :integer)
        end

        it "raises an error if using the same column name" do
          expect {
            table.add_column_from_database(:column_name, :integer)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::LoadedColumnAlreadyExistsError
        end
      end
    end

    describe :loaded_column do
      it "returns nil" do
        expect(table.loaded_column(:column_name)).to be_nil
      end

      describe "after the expected column has been added" do
        let(:column) { table.add_column_from_database :column_name, :integer }

        before(:each) do
          column
        end

        it "returns the column" do
          expect(table.loaded_column(:column_name)).to eq(column)
        end
      end
    end

    describe :loaded_columns do
      it "returns an empty array" do
        expect(table.loaded_columns).to be_an Array
        expect(table.loaded_columns).to be_empty
      end

      describe "after the expected column has been added" do
        let(:column) { table.add_column_from_database :column_name, :integer }

        before(:each) do
          column
        end

        it "returns an array of the expected columns" do
          expect(table.loaded_columns).to eql([column])
        end
      end
    end

    describe :fetch_columns do
      it "raises an error" do
        expect {
          table.fetch_columns
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          table.schema.database.connect
        end

        it "returns an empty array" do
          expect(table.fetch_columns).to be_empty
        end

        describe "after a column has been added" do
          before :each do
            pg_helper.create_schema :my_schema
            pg_helper.create_table :my_schema, :my_table
            pg_helper.create_column :my_schema, :my_table, :my_column, :integer
          end

          it "returns the expected array" do
            expect(table.fetch_columns).to eql [{column_name: :my_column, type: :integer}]
          end
        end
      end
    end

    describe :load_columns do
      it "raises an error" do
        expect {
          table.load_columns
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          table.schema.database.connect
        end

        it "does not raise an error" do
          expect {
            table.load_columns
          }.to_not raise_error
        end

        it "does not add any columns to the database object" do
          table.load_columns
          expect(table.loaded_columns).to be_empty
        end

        describe "after a column has been added" do
          before :each do
            pg_helper.create_schema :my_schema
            pg_helper.create_table :my_schema, :my_table
            pg_helper.create_column :my_schema, :my_table, :my_column, :integer
          end

          it "does add a columns to the database object" do
            table.load_columns
            expect(table.loaded_columns.count).to eq(1)
            expect(table.loaded_columns.first.column_name).to eq(:my_column)
          end
        end
      end
    end
  end
end
