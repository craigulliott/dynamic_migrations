# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :Loader do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :fetch_schema_names do
      it "raises an error" do
        expect {
          database.fetch_schema_names
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty array" do
          expect(database.fetch_schema_names).to be_empty
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "returns the expected array" do
            expect(database.fetch_schema_names).to eql ["my_schema"]
          end
        end
      end
    end

    describe :fetch_table_names do
      it "raises an error" do
        expect {
          database.fetch_table_names :my_schema
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty array" do
          expect(database.fetch_table_names(:my_schema)).to be_empty
        end

        describe "after a table has been added" do
          before :each do
            pg_helper.create_schema :my_schema
            pg_helper.create_table :my_schema, :my_table
          end

          it "returns the expected array" do
            expect(database.fetch_table_names(:my_schema)).to eql ["my_table"]
          end
        end
      end
    end

    describe :fetch_columns do
      it "raises an error" do
        expect {
          database.fetch_columns(:my_schema, :my_table)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty array" do
          expect(database.fetch_columns(:my_schema, :my_table)).to be_empty
        end

        describe "after a column has been added" do
          before :each do
            pg_helper.create_schema :my_schema
            pg_helper.create_table :my_schema, :my_table
            pg_helper.create_column :my_schema, :my_table, :my_column, :integer
          end

          it "returns the expected array" do
            expect(database.fetch_columns(:my_schema, :my_table)).to eql [{column_name: :my_column, type: :integer}]
          end
        end
      end
    end
  end
end
