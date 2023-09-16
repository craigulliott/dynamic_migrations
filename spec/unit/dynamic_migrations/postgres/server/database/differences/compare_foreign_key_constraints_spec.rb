# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:configured_table) { configured_schema.add_table :my_table }

  let(:loaded_schema) { database.add_loaded_schema :my_schema }
  let(:loaded_table) { loaded_schema.add_table :my_table }

  describe :compare_foreign_key_constraints do
    describe "when base table has no foreign key constraints" do
      let(:base) { configured_table }

      describe "when comparison table has no foreign key constraints" do
        let(:comparison) { loaded_table }

        it "returns an empty object" do
          expect(differences_class.compare_foreign_key_constraints(base.foreign_key_constraints_hash, comparison.foreign_key_constraints_hash)).to eql({})
        end
      end

      describe "when comparison table has a foreign key constraint" do
        let(:comparison) { loaded_table }

        before(:each) do
          # create a table and columns for the foreign key to point to
          foreign_table = loaded_schema.add_table :foreign_table
          foreign_table.add_column :foreign_column, :boolean
          foreign_table.add_unique_constraint :foreign_unique_constraint, [:foreign_column]
          # create the foreign key constraint
          comparison.add_column :local_column, :boolean
          comparison.add_foreign_key_constraint :foreign_key_constraint, [:local_column], foreign_table.schema.name, foreign_table.name, [:foreign_column]
        end

        it "returns the expected object" do
          expect(differences_class.compare_foreign_key_constraints(base.foreign_key_constraints_hash, comparison.foreign_key_constraints_hash)).to eql({
            foreign_key_constraint: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base table has a foreign key constraint" do
      let(:base) { configured_table }

      before(:each) do
        # create a table and columns for the foreign key to point to
        foreign_table = configured_schema.add_table :foreign_table
        foreign_table.add_column :foreign_column, :boolean
        foreign_table.add_unique_constraint :foreign_unique_constraint, [:foreign_column]
        # create the foreign key constraint
        base.add_column :local_column, :boolean
        base.add_foreign_key_constraint :foreign_key_constraint, [:local_column], foreign_table.schema.name, foreign_table.name, [:foreign_column]
      end

      describe "when comparison table has no foreign key constraints" do
        let(:comparison) { loaded_table }

        it "returns the expected object" do
          expect(differences_class.compare_foreign_key_constraints(base.foreign_key_constraints_hash, comparison.foreign_key_constraints_hash)).to eql({foreign_key_constraint:             {
            exists: true,
            column_names: {
              value: [:local_column],
              matches: false
            },
            foreign_schema_name: {
              value: :my_schema,
              matches: false
            },
            foreign_table_name: {
              value: :foreign_table,
              matches: false
            },
            foreign_column_names: {
              value: [:foreign_column],
              matches: false
            },
            description: {
              value: nil,
              matches: false
            },
            deferrable: {
              value: false,
              matches: false
            },
            initially_deferred: {
              value: false,
              matches: false
            },
            on_delete: {
              value: :no_action,
              matches: false
            },
            on_update: {
              value: :no_action,
              matches: false
            }
          }})
        end
      end

      describe "when comparison table has an equivilent foreign key constraint" do
        let(:comparison) { loaded_table }

        before(:each) do
          # create a table and columns for the foreign key to point to
          foreign_table = loaded_schema.add_table :foreign_table
          foreign_table.add_column :foreign_column, :boolean
          foreign_table.add_unique_constraint :foreign_unique_constraint, [:foreign_column]
          # create the foreign key constraint
          comparison.add_column :local_column, :boolean
          comparison.add_foreign_key_constraint :foreign_key_constraint, [:local_column], foreign_table.schema.name, foreign_table.name, [:foreign_column]
        end

        it "returns the expected object" do
          expect(differences_class.compare_foreign_key_constraints(base.foreign_key_constraints_hash, comparison.foreign_key_constraints_hash)).to eql({foreign_key_constraint:             {
            exists: true,
            column_names: {
              value: [:local_column],
              matches: true
            },
            foreign_schema_name: {
              value: :my_schema,
              matches: true
            },
            foreign_table_name: {
              value: :foreign_table,
              matches: true
            },
            foreign_column_names: {
              value: [:foreign_column],
              matches: true
            },
            description: {
              value: nil,
              matches: true
            },
            deferrable: {
              value: false,
              matches: true
            },
            initially_deferred: {
              value: false,
              matches: true
            },
            on_delete: {
              value: :no_action,
              matches: true
            },
            on_update: {
              value: :no_action,
              matches: true
            }
          }})
        end
      end

      describe "when comparison table has a different foreign key constraint" do
        let(:comparison) { loaded_table }

        before(:each) do
          # create a table and columns for the foreign key to point to
          foreign_table = loaded_schema.add_table :different_foreign_table_name
          foreign_table.add_column :different_foreign_column_name, :boolean
          foreign_table.add_unique_constraint :foreign_unique_constraint, [:different_foreign_column_name]
          # create the foreign key constraint
          comparison.add_column :local_column, :boolean
          comparison.add_foreign_key_constraint :foreign_key_constraint, [:local_column], foreign_table.schema.name, foreign_table.name, [:different_foreign_column_name]
        end

        it "returns the expected object" do
          expect(differences_class.compare_foreign_key_constraints(base.foreign_key_constraints_hash, comparison.foreign_key_constraints_hash)).to eql({foreign_key_constraint:             {
            exists: true,
            column_names: {
              value: [:local_column],
              matches: true
            },
            foreign_schema_name: {
              value: :my_schema,
              matches: true
            },
            foreign_table_name: {
              value: :foreign_table,
              matches: false
            },
            foreign_column_names: {
              value: [:foreign_column],
              matches: false
            },
            description: {
              value: nil,
              matches: true
            },
            deferrable: {
              value: false,
              matches: true
            },
            initially_deferred: {
              value: false,
              matches: true
            },
            on_delete: {
              value: :no_action,
              matches: true
            },
            on_update: {
              value: :no_action,
              matches: true
            }
          }})
        end
      end
    end
  end
end
