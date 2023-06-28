# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :ConfiguredSchemas do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :add_schema_from_configuration do
      it "creates a new schema object" do
        expect(database.add_schema_from_configuration(:schema_name)).to be_a DynamicMigrations::Postgres::Server::Database::Schema
      end

      it "raises an error if providing an invalid schema name" do
        expect {
          database.add_schema_from_configuration "schema_name"
        }.to raise_error DynamicMigrations::Postgres::Server::Database::ExpectedSymbolError
      end

      describe "when a schema already exists" do
        before(:each) do
          database.add_schema_from_configuration(:schema_name)
        end

        it "raises an error if using the same schema name" do
          expect {
            database.add_schema_from_configuration(:schema_name)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::ConfiguredSchemaAlreadyExistsError
        end
      end
    end

    describe :configured_schema do
      it "returns nil" do
        expect(database.configured_schema(:schema_name)).to be_nil
      end

      describe "after the expected schema has been added" do
        let(:schema) { database.add_schema_from_configuration :schema_name }

        before(:each) do
          schema
        end

        it "returns the schema" do
          expect(database.configured_schema(:schema_name)).to eq(schema)
        end
      end
    end

    describe :configured_schemas do
      it "returns an empty array" do
        expect(database.configured_schemas).to be_an Array
        expect(database.configured_schemas).to be_empty
      end

      describe "after the expected schema has been added" do
        let(:schema) { database.add_schema_from_configuration :schema_name }

        before(:each) do
          schema
        end

        it "returns an array of the expected schemas" do
          expect(database.configured_schemas).to eql([schema])
        end
      end
    end
  end
end
