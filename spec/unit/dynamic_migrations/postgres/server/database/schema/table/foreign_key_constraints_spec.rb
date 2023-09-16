# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { database.add_loaded_schema :my_schema }
  let(:table) { schema.add_table :my_table }
  let(:foreign_schema) { database.add_loaded_schema :my_foreign_schema }
  let(:foreign_table) { foreign_schema.add_table :my_foreign_table }

  describe :ForeignKeyConstraints do
    describe :add_foreign_key_constraint do
      before(:each) do
        table.add_column :my_column, :boolean
        foreign_table.add_column :my_foreign_column, :boolean
      end

      it "creates a new foreign_key_constraint object" do
        expect(table.add_foreign_key_constraint(:foreign_key_constraint_name, [:my_column], :my_foreign_schema, :my_foreign_table, [:my_foreign_column])).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraint
      end

      describe "when a foreign_key_constraint already exists" do
        before(:each) do
          table.add_foreign_key_constraint(:foreign_key_constraint_name, [:my_column], :my_foreign_schema, :my_foreign_table, [:my_foreign_column])
        end

        it "raises an error if using the same foreign_key_constraint name" do
          expect {
            table.add_foreign_key_constraint(:foreign_key_constraint_name, [:my_column], :my_foreign_schema, :my_foreign_table, [:my_foreign_column])
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraintAlreadyExistsError
        end
      end
    end

    describe :foreign_key_constraint do
      it "raises an error" do
        expect {
          table.foreign_key_constraint(:foreign_key_constraint_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ForeignKeyConstraintDoesNotExistError
      end

      describe "after the expected foreign_key_constraint has been added" do
        let(:foreign_key_constraint) { table.add_foreign_key_constraint(:foreign_key_constraint_name, [:my_column], :my_foreign_schema, :my_foreign_table, [:my_foreign_column]) }

        before(:each) do
          table.add_column :my_column, :boolean
          foreign_table.add_column :my_foreign_column, :boolean
          foreign_key_constraint
        end

        it "returns the foreign_key_constraint" do
          expect(table.foreign_key_constraint(:foreign_key_constraint_name)).to eq(foreign_key_constraint)
        end
      end
    end

    describe :has_foreign_key_constraint? do
      it "returns false" do
        expect(table.has_foreign_key_constraint?(:foreign_key_constraint_name)).to be(false)
      end

      describe "after the expected foreign_key_constraint has been added" do
        before(:each) do
          table.add_column :my_column, :boolean
          foreign_table.add_column :my_foreign_column, :boolean
          table.add_foreign_key_constraint(:foreign_key_constraint_name, [:my_column], :my_foreign_schema, :my_foreign_table, [:my_foreign_column])
        end

        it "returns true" do
          expect(table.has_foreign_key_constraint?(:foreign_key_constraint_name)).to be(true)
        end
      end
    end

    describe :foreign_key_constraints do
      it "returns an empty array" do
        expect(table.foreign_key_constraints).to be_an Array
        expect(table.foreign_key_constraints).to be_empty
      end

      describe "after the expected foreign_key_constraint has been added" do
        let(:foreign_key_constraint) { table.add_foreign_key_constraint(:foreign_key_constraint_name, [:my_column], :my_foreign_schema, :my_foreign_table, [:my_foreign_column]) }

        before(:each) do
          table.add_column :my_column, :boolean
          foreign_table.add_column :my_foreign_column, :boolean
          foreign_key_constraint
        end

        it "returns an array of the expected foreign_key_constraints" do
          expect(table.foreign_key_constraints).to eql([foreign_key_constraint])
        end
      end
    end

    describe :foreign_key_constraints_hash do
      it "returns an empty object" do
        expect(table.foreign_key_constraints_hash).to eql({})
      end

      describe "after the expected foreign_key_constraint has been added" do
        let(:foreign_key_constraint) { table.add_foreign_key_constraint(:foreign_key_constraint_name, [:my_column], :my_foreign_schema, :my_foreign_table, [:my_foreign_column]) }

        before(:each) do
          table.add_column :my_column, :boolean
          foreign_table.add_column :my_foreign_column, :boolean
          foreign_key_constraint
        end

        it "returns a hash representation of the expected columns foreign_key_constraints" do
          expect(table.foreign_key_constraints_hash).to eql({foreign_key_constraint_name: foreign_key_constraint})
        end
      end
    end
  end
end
