# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Enum do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:enum) { DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, enum_values }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:enum_values) { ["foo", "bar"] }

  describe :initialize do
    it "instantiates a new enum without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, enum_values
      }.to_not raise_error
    end

    it "raises an error if providing an invalid schema" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, "not a schema object", :my_enum, enum_values
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Enum::ExpectedSchemaError
    end

    it "raises an error if providing an invalid enum name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, "my_enum", enum_values
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    it "raises an error if providing invalid values" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, :this_should_be_an_array
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Enum::ExpectedValuesError
    end

    it "raises an error if providing no values" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, []
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Enum::ExpectedValuesError
    end

    describe "when providing an optional description" do
      it "instantiates a new enum without raising an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, enum_values, description: "a valid description of my enum"
        }.to_not raise_error
      end

      it "raises an error if providing an invalid description" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, enum_values, description: :an_invalid_description_type
        }.to raise_error DynamicMigrations::ExpectedStringError
      end
    end
  end

  describe :schema do
    it "returns the expected schema" do
      expect(enum.schema).to eq(schema)
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(enum.name).to eq(:my_enum)
    end
  end

  describe :full_name do
    it "returns the expected full_name" do
      expect(enum.full_name).to eq(:"my_schema.my_enum")
    end
  end

  describe :values do
    it "returns the expected values" do
      expect(enum.values).to eql ["foo", "bar"]
    end
  end

  describe :add_value do
    it "adds a new value" do
      expect(enum.values).to eql ["foo", "bar"]

      enum.add_value("new_value")

      expect(enum.values).to eql ["foo", "bar", "new_value"]
    end

    it "raises an error if a symbol is provided (because it requires a String)" do
      expect {
        enum.add_value(:foo)
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Enum::ValueMustBeStringError
    end

    it "raises an error if the value is too long" do
      expect {
        enum.add_value("a" * 64)
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Enum::EnumValueTooLongError
    end
  end

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(enum.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:enum_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, enum_values, description: "a valid description of my enum" }
      it "returns the expected description" do
        expect(enum_with_description.description).to eq("a valid description of my enum")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(enum.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:enum_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, enum_values, description: "a valid description of my enum" }
      it "returns true" do
        expect(enum_with_description.has_description?).to be(true)
      end
    end
  end

  describe :add_column do
    # Can not directly test this method because it is called automatically when
    # a column is instantiated. The column specs adequately cover this method.
  end

  describe :differences_descriptions do
    describe "when compared to a enum which has different values" do
      let(:different_enum) {
        DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, ["a", "b"]
      }

      it "returns the expected array which describes the differences" do
        expect(enum.differences_descriptions(different_enum)).to eql([
          <<~CHANGES.strip
            values changed from `["foo", "bar"]` to `["a", "b"]`
          CHANGES
        ])
      end
    end
  end
end
