# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }

  describe :Validations do
    describe :add_validation do
      before(:each) do
        table.add_column :column_name, :boolean
      end

      it "creates a new validation object" do
        expect(table.add_validation(:validation_name, [:column_name], "(column_name IS TRUE)")).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation
      end

      describe "when a validation already exists" do
        before(:each) do
          table.add_validation(:validation_name, [:column_name], "(column_name IS TRUE)")
        end

        it "raises an error if using the same validation name" do
          expect {
            table.add_validation(:validation_name, [:column_name], "(column_name IS TRUE)")
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ValidationAlreadyExistsError
        end
      end
    end

    describe :validation do
      it "raises an error" do
        expect {
          table.validation(:validation_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::ValidationDoesNotExistError
      end

      describe "after the expected validation has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:validation) { table.add_validation :validation_name, [:column_name], "(column_name IS TRUE)" }

        before(:each) do
          column
          validation
        end

        it "returns the validation" do
          expect(table.validation(:validation_name)).to eq(validation)
        end
      end
    end

    describe :has_validation? do
      it "returns false" do
        expect(table.has_validation?(:validation_name)).to be(false)
      end

      describe "after the expected validation has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:validation) { table.add_validation :validation_name, [:column_name], "(column_name IS TRUE)" }

        before(:each) do
          column
          validation
        end

        it "returns true" do
          expect(table.has_validation?(:validation_name)).to be(true)
        end
      end
    end

    describe :validations do
      it "returns an empty array" do
        expect(table.validations).to be_an Array
        expect(table.validations).to be_empty
      end

      describe "after the expected validation has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:validation) { table.add_validation :validation_name, [:column_name], "(column_name IS TRUE)" }

        before(:each) do
          column
          validation
        end

        it "returns an array of the expected validations" do
          expect(table.validations).to eql([validation])
        end
      end
    end

    describe :validations_hash do
      it "returns an empty object" do
        expect(table.validations_hash).to eql({})
      end

      describe "after the expected validation has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:validation) { table.add_validation :validation_name, [:column_name], "(column_name IS TRUE)" }

        before(:each) do
          column
          validation
        end

        it "returns a hash representation of the expected validations" do
          expect(table.validations_hash).to eql({validation_name: validation})
        end
      end
    end
  end
end
