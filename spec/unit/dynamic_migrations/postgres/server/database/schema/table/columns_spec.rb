# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }

  describe :Columns do
    describe :add_column do
      it "creates a new column object" do
        expect(table.add_column(:column_name, :boolean)).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::Column
      end

      it "raises an error if providing an invalid column name" do
        expect {
          table.add_column "column_name", :integer
        }.to raise_error DynamicMigrations::ExpectedSymbolError
      end

      describe "when a column already exists" do
        before(:each) do
          table.add_column(:column_name, :boolean)
        end

        it "raises an error if using the same column name" do
          expect {
            table.add_column(:column_name, :boolean)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Columns::DuplicateColumnError
        end
      end
    end

    describe :column do
      it "raises an error" do
        expect {
          table.column(:column_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ColumnDoesNotExistError
      end

      describe "after the expected column has been added" do
        let(:column) { table.add_column :column_name, :boolean }

        before(:each) do
          column
        end

        it "returns the column" do
          expect(table.column(:column_name)).to eq(column)
        end
      end
    end

    describe :has_column? do
      it "returns false" do
        expect(table.has_column?(:column_name)).to be(false)
      end

      describe "after the expected column has been added" do
        let(:column) { table.add_column :column_name, :boolean }

        before(:each) do
          column
        end

        it "returns true" do
          expect(table.has_column?(:column_name)).to be(true)
        end
      end
    end

    describe :columns do
      it "returns an empty array" do
        expect(table.columns).to be_an Array
        expect(table.columns).to be_empty
      end

      describe "after the expected column has been added" do
        let(:column) { table.add_column :column_name, :boolean }

        before(:each) do
          column
        end

        it "returns an array of the expected columns" do
          expect(table.columns).to eql([column])
        end
      end
    end

    describe :columns_hash do
      it "returns an empty hash" do
        expect(table.columns_hash).to eql({})
      end

      describe "after the expected schema has been added" do
        let(:column) { table.add_column :my_column, :boolean }

        before(:each) do
          column
        end

        it "returns a hash representation of the expected columns" do
          expect(table.columns_hash).to eql({my_column: column})
        end
      end
    end
  end
end
