# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :LoadedSchemas do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :add_schema_from_database do
      it "creates a new schema object" do
        expect(database.add_schema_from_database(:schema_name)).to be_a DynamicMigrations::Postgres::Server::Database::Schema
      end

      it "raises an error if providing an invalid schema name" do
        expect {
          database.add_schema_from_database "my_database"
        }.to raise_error DynamicMigrations::Postgres::Server::Database::ExpectedSymbolError
      end

      describe "when a schema already exists" do
        before(:each) do
          database.add_schema_from_database(:schema_name)
        end

        it "raises an error if using the same schema name" do
          expect {
            database.add_schema_from_database(:schema_name)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::LoadedSchemaAlreadyExistsError
        end
      end
    end

    describe :loaded_schema do
      it "returns nil" do
        expect(database.loaded_schema(:schema_name)).to be_nil
      end

      describe "after the expected schema has been added" do
        let(:schema) { database.add_schema_from_database :schema_name }

        before(:each) do
          schema
        end

        it "returns the schema" do
          expect(database.loaded_schema(:schema_name)).to eq(schema)
        end
      end
    end

    describe :loaded_schemas do
      it "returns an empty array" do
        expect(database.loaded_schemas).to be_an Array
        expect(database.loaded_schemas).to be_empty
      end

      describe "after the expected schema has been added" do
        let(:schema) { database.add_schema_from_database :schema_name }

        before(:each) do
          schema
        end

        it "returns an array of the expected schemas" do
          expect(database.loaded_schemas).to eql([schema])
        end
      end
    end

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
            pg_helper.create_schema :foo
          end

          it "returns the expected array" do
            expect(database.fetch_schema_names).to eql ["foo"]
          end
        end
      end
    end

    describe :load_schemas do
      it "raises an error" do
        expect {
          database.load_schemas
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "does not raise an error" do
          expect {
            database.load_schemas
          }.to_not raise_error
        end

        it "does not add any schemas to the database object" do
          database.load_schemas
          expect(database.loaded_schemas).to be_empty
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :foo
          end

          it "does add a schemas to the database object" do
            database.load_schemas
            expect(database.loaded_schemas.count).to eq(1)
            expect(database.loaded_schemas.first.schema_name).to eq(:foo)
          end
        end
      end
    end
  end
end
