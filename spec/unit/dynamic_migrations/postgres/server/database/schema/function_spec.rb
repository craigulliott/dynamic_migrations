# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Function do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:function) { DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, "NEW.column = 0" }

  describe :initialize do
    it "instantiates a new function without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, "NEW.column = 0"
      }.to_not raise_error
    end

    it "raises an error if providing an invalid schema" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, "not a schema object", :my_function, "NEW.column = 0"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Function::ExpectedSchemaError
    end

    it "raises an error if providing an invalid function name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, "my_function", "NEW.column = 0"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    it "raises an error if providing an invalid definition" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, 123
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Function::ExpectedDefinitionError
    end

    describe "when providing an optional description" do
      it "instantiates a new function without raising an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, "NEW.column = 0", description: "a valid description of my function"
        }.to_not raise_error
      end

      it "raises an error if providing an invalid description" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, "NEW.column = 0", description: :an_invalid_description_type
        }.to raise_error DynamicMigrations::ExpectedStringError
      end
    end
  end

  describe :schema do
    it "returns the expected schema" do
      expect(function.schema).to eq(schema)
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(function.name).to eq(:my_function)
    end
  end

  describe :definition do
    it "returns the expected definition" do
      expect(function.definition).to eq("NEW.column = 0")
    end
  end

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(function.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:function_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, "NEW.column = 0", description: "a valid description of my function" }
      it "returns the expected description" do
        expect(function_with_description.description).to eq("a valid description of my function")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(function.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:function_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, "NEW.column = 0", description: "a valid description of my function" }
      it "returns true" do
        expect(function_with_description.has_description?).to be(true)
      end
    end
  end
end
