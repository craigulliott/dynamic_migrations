# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::Column do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:enum) { DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, enum_values }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean }
  let(:enum_values) { ["foo", "bar"] }

  describe :initialize do
    it "instantiates a new column without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean
      }.to_not raise_error
    end

    it "raises an error if providing an invalid schema" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, "not a schema object", :my_column, :boolean
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Column::ExpectedTableError
    end

    it "raises an error if providing an invalid column name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, "my_column", :integer
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    it "raises an error if providing a string instead of a symbol for the data type" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, "integer"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    it "raises an error if providing a data type which does not match the provided enum" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :integer, enum: enum
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Column::UnexpectedEnumError
    end

    describe "when providing an optional description" do
      it "instantiates a new column without raising an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean, description: "a valid description of my table"
        }.to_not raise_error
      end

      it "raises an error if providing an invalid description" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean, description: :an_invalid_description_type
        }.to raise_error DynamicMigrations::ExpectedStringError
      end
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(column.table).to eq(table)
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(column.name).to eq(:my_column)
    end
  end

  describe :data_type do
    it "returns the expected data_type" do
      expect(column.data_type).to eq(:boolean)
    end
  end

  describe :temp_table_data_type do
    describe "when an enum data type was provided at initialization" do
      let(:enum_column) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :"my_schema.my_enum", enum: enum, description: "a valid description of my column" }

      it "returns the expected temp_table_data_type" do
        expect(enum_column.temp_table_data_type).to eq(:text)
      end
    end
  end

  describe :array? do
    it "returns false because this data type is not an array" do
      expect(column.array?).to be false
    end

    describe "when an array data type was provided at initialization" do
      let(:array_column) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :"integer[]", description: "a valid description of my column" }
      it "returns true because this is an array" do
        expect(array_column.array?).to be true
      end
    end
  end

  describe :base_data_type do
    it "returns the same column type as the internal column_type value because this data type is not an array" do
      expect(column.base_data_type).to eq :boolean
    end

    describe "when an array data type was provided at initialization" do
      let(:array_column) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :"boolean[]", description: "a valid description of my column" }
      it "returns the data type without the square brackets because this is an array" do
        expect(column.base_data_type).to eq :boolean
      end
    end
  end

  describe :enum do
    it "returns nil because this data type is not an enum" do
      expect(column.enum).to be nil
    end

    describe "when an enum data type was provided at initialization" do
      let(:enum_column) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :"my_schema.my_enum", enum: enum, description: "a valid description of my column" }
      it "returns the expected enum" do
        expect(enum_column.enum).to be enum
      end
    end
  end

  describe :enum? do
    it "returns flse because this data type is not an enum" do
      expect(column.enum?).to be false
    end

    describe "when an enum data type was provided at initialization" do
      let(:enum_column) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :"my_schema.my_enum", enum: enum, description: "a valid description of my column" }
      it "returns true" do
        expect(enum_column.enum?).to be true
      end
    end
  end

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(column.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:column_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean, description: "a valid description of my column" }
      it "returns the expected description" do
        expect(column_with_description.description).to eq("a valid description of my column")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(column.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:column_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Column.new :configuration, table, :my_column, :boolean, description: "a valid description of my column" }
      it "returns true" do
        expect(column_with_description.has_description?).to be(true)
      end
    end
  end
end
