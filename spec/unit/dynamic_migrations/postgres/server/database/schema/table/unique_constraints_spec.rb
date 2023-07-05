# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }

  describe :UniqueConstraints do
    describe :add_unique_constraint do
      before(:each) do
        table.add_column :column_name, :boolean
      end

      it "creates a new unique_constraint object" do
        expect(table.add_unique_constraint(:unique_constraint_name, [:column_name])).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint
      end

      describe "when a unique_constraint already exists" do
        before(:each) do
          table.add_unique_constraint(:unique_constraint_name, [:column_name])
        end

        it "raises an error if using the same unique_constraint name" do
          expect {
            table.add_unique_constraint(:unique_constraint_name, [:column_name])
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraintAlreadyExistsError
        end
      end
    end

    describe :unique_constraint do
      it "raises an error" do
        expect {
          table.unique_constraint(:unique_constraint_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraintDoesNotExistError
      end

      describe "after the expected unique_constraint has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:unique_constraint) { table.add_unique_constraint :unique_constraint_name, [:column_name] }

        before(:each) do
          column
          unique_constraint
        end

        it "returns the unique_constraint" do
          expect(table.unique_constraint(:unique_constraint_name)).to eq(unique_constraint)
        end
      end
    end

    describe :has_unique_constraint? do
      it "returns false" do
        expect(table.has_unique_constraint?(:unique_constraint_name)).to be(false)
      end

      describe "after the expected unique_constraint has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:unique_constraint) { table.add_unique_constraint :unique_constraint_name, [:column_name] }

        before(:each) do
          column
          unique_constraint
        end

        it "returns true" do
          expect(table.has_unique_constraint?(:unique_constraint_name)).to be(true)
        end
      end
    end

    describe :unique_constraints do
      it "returns an empty array" do
        expect(table.unique_constraints).to be_an Array
        expect(table.unique_constraints).to be_empty
      end

      describe "after the expected unique_constraint has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:unique_constraint) { table.add_unique_constraint :unique_constraint_name, [:column_name] }

        before(:each) do
          column
          unique_constraint
        end

        it "returns an array of the expected unique_constraints" do
          expect(table.unique_constraints).to eql([unique_constraint])
        end
      end
    end

    describe :unique_constraints_hash do
      it "returns an empty object" do
        expect(table.unique_constraints_hash).to eql({})
      end

      describe "after the expected unique_constraint has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:unique_constraint) { table.add_unique_constraint :unique_constraint_name, [:column_name] }

        before(:each) do
          column
          unique_constraint
        end

        it "returns a hash representation of the expected unique_constraints" do
          expect(table.unique_constraints_hash).to eql({unique_constraint_name: unique_constraint})
        end
      end
    end
  end
end
