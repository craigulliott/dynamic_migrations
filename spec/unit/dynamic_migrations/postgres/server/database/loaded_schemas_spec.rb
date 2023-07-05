# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :LoadedSchemas do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :add_loaded_schema do
      it "creates a new schema object" do
        expect(database.add_loaded_schema(:schema_name)).to be_a DynamicMigrations::Postgres::Server::Database::Schema
      end

      it "raises an error if providing an invalid schema name" do
        expect {
          database.add_loaded_schema "my_database"
        }.to raise_error DynamicMigrations::ExpectedSymbolError
      end

      describe "when a schema already exists" do
        before(:each) do
          database.add_loaded_schema(:schema_name)
        end

        it "raises an error if using the same schema name" do
          expect {
            database.add_loaded_schema(:schema_name)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::LoadedSchemaAlreadyExistsError
        end
      end
    end

    describe :loaded_schema do
      it "raises an error" do
        expect {
          database.loaded_schema(:schema_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::LoadedSchemaDoesNotExistError
      end

      describe "after the expected schema has been added" do
        let(:schema) { database.add_loaded_schema :schema_name }

        before(:each) do
          schema
        end

        it "returns the schema" do
          expect(database.loaded_schema(:schema_name)).to eq(schema)
        end
      end
    end

    describe :has_loaded_schema? do
      it "returns false" do
        expect(database.has_loaded_schema?(:loaded_schema)).to be(false)
      end

      describe "after the expected loaded_schema has been added" do
        let(:loaded_schema) { database.add_loaded_schema :loaded_schema }

        before(:each) do
          loaded_schema
        end

        it "returns true" do
          expect(database.has_loaded_schema?(:loaded_schema)).to be(true)
        end
      end
    end

    describe :loaded_schemas do
      it "returns an empty array" do
        expect(database.loaded_schemas).to be_an Array
        expect(database.loaded_schemas).to be_empty
      end

      describe "after the expected schema has been added" do
        let(:schema) { database.add_loaded_schema :schema_name }

        before(:each) do
          schema
        end

        it "returns an array of the expected schemas" do
          expect(database.loaded_schemas).to eql([schema])
        end
      end
    end

    describe :loaded_schemas_hash do
      it "returns an empty hash" do
        expect(database.loaded_schemas_hash).to eql({})
      end

      describe "after the expected schema has been added" do
        let(:schema) { database.add_loaded_schema :schema_name }

        before(:each) do
          schema
        end

        it "returns a hash representation of the expected schemas" do
          expect(database.loaded_schemas_hash).to eql({schema_name: schema})
        end
      end
    end
  end
end
