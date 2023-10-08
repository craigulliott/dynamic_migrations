# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }

  describe :initialize do
    it "instantiates a new table without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table
      }.to_not raise_error
    end

    it "raises an error if providing an invalid schema" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, "not a schema object", :my_table
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ExpectedSchemaError
    end

    it "raises an error if providing an invalid table name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, "my_table"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    describe "when providing an optional description" do
      it "instantiates a new table without raising an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "a valid description of my table"
        }.to_not raise_error
      end

      it "raises an error if providing an invalid description" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: :an_invalid_description_type
        }.to raise_error DynamicMigrations::ExpectedStringError
      end
    end
  end

  describe :schema do
    it "returns the expected schema" do
      expect(table.schema).to eq(schema)
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(table.name).to eq(:my_table)
    end
  end

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(table.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:table_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "a valid description of my table" }
      it "returns the expected description" do
        expect(table_with_description.description).to eq("a valid description of my table")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(table.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:table_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "a valid description of my table" }
      it "returns true" do
        expect(table_with_description.has_description?).to be(true)
      end
    end
  end

  describe :add_primary_key do
    before(:each) do
      table.add_column :my_column, :boolean
    end

    it "adds and returns a primary key" do
      expect(table.add_primary_key(:pk_name, [:my_column])).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey
    end
  end

  describe :has_primary_key? do
    it "returns false" do
      expect(table.has_primary_key?).to be(false)
    end

    describe "after a primary key has been added" do
      before(:each) do
        table.add_column :my_column, :boolean
        table.add_primary_key(:pk_name, [:my_column])
      end

      it "returns true" do
        expect(table.has_primary_key?).to be(true)
      end
    end
  end

  describe :primary_key do
    it "raises an error" do
      expect {
        table.primary_key
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKeyDoesNotExistError
    end

    describe "after a primary key has been added" do
      let(:primary_key) { table.add_primary_key(:pk_name, [:my_column]) }
      before(:each) do
        table.add_column :my_column, :boolean
        primary_key
      end

      it "returns the primary key" do
        expect(table.primary_key).to be(primary_key)
      end
    end
  end

  describe :create_temp_table do
    let(:connection) { database.connect }

    # this method is usually called from witin a validation or trigger, which
    # create a transaction and pass the connection object to this method
    # adding our own transaction here so that if this spec fails, we don't
    # leave the temporary table or any temporary enums behind
    before(:each) do
      connection.exec("BEGIN")
    end

    after(:each) do
      connection.exec("ROLLBACK")
    end

    subject {
      table.create_temp_table connection, "temp_table_name"
    }

    it "creates the requested table" do
      subject
      expect(connection.exec(<<~SQL).first["exists"]).to eq("1")
        SELECT 1 as exists
        FROM   pg_tables
        WHERE  tablename  = 'temp_table_name'
      SQL
    end
  end
end
