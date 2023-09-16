# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }

  describe :Indexes do
    describe :add_index do
      before(:each) do
        table.add_column :column_name, :boolean
      end

      it "creates a new index object" do
        expect(table.add_index(:index_name, [:column_name])).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::Index
      end

      describe "when a index already exists" do
        before(:each) do
          table.add_index(:index_name, [:column_name])
        end

        it "raises an error if using the same index name" do
          expect {
            table.add_index(:index_name, [:column_name])
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::IndexAlreadyExistsError
        end
      end
    end

    describe :index do
      it "raises an error" do
        expect {
          table.index(:index_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::IndexDoesNotExistError
      end

      describe "after the expected index has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:index) { table.add_index :index_name, [:column_name] }

        before(:each) do
          column
          index
        end

        it "returns the index" do
          expect(table.index(:index_name)).to eq(index)
        end
      end
    end

    describe :has_index? do
      it "returns false" do
        expect(table.has_index?(:index_name)).to be(false)
      end

      describe "after the expected index has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:index) { table.add_index :index_name, [:column_name] }

        before(:each) do
          column
          index
        end

        it "returns true" do
          expect(table.has_index?(:index_name)).to be(true)
        end
      end
    end

    describe :indexes do
      it "returns an empty array" do
        expect(table.indexes).to be_an Array
        expect(table.indexes).to be_empty
      end

      describe "after the expected index has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:index) { table.add_index :index_name, [:column_name] }

        before(:each) do
          column
          index
        end

        it "returns an array of the expected indexes" do
          expect(table.indexes).to eql([index])
        end
      end
    end

    describe :indexes_hash do
      it "returns an empty hash" do
        expect(table.indexes_hash).to eql({})
      end

      describe "after the expected index has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:index) { table.add_index :index_name, [:column_name] }

        before(:each) do
          column
          index
        end

        it "returns a hash representation of the expected indexes" do
          expect(table.indexes_hash).to eql({index_name: index})
        end
      end
    end
  end
end
