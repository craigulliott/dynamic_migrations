# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }

  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:configured_table) { configured_schema.add_table :my_table }

  let(:loaded_schema) { database.add_loaded_schema :my_schema }
  let(:loaded_table) { loaded_schema.add_table :my_table }

  describe :compare_unique_constraints do
    describe "when base table has no unique_constraints" do
      let(:base) { configured_table }

      describe "when comparison table has no unique_constraints" do
        let(:comparison) { loaded_table }

        it "returns an empty object" do
          expect(differences_class.compare_unique_constraints(base.unique_constraints_hash, comparison.unique_constraints_hash)).to eql({})
        end
      end

      describe "when comparison table has a unique_constraint" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :boolean
          comparison.add_unique_constraint :unique_constraint_name, [:column_name]
        end

        it "returns the expected object" do
          expect(differences_class.compare_unique_constraints(base.unique_constraints_hash, comparison.unique_constraints_hash)).to eql({
            unique_constraint_name: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base table has a unique_constraint" do
      let(:base) { configured_table }

      before(:each) do
        base.add_column :column_name, :boolean
        base.add_unique_constraint :unique_constraint_name, [:column_name]
      end

      describe "when comparison table has no unique_constraints" do
        let(:comparison) { loaded_table }

        it "returns the expected object" do
          expect(differences_class.compare_unique_constraints(base.unique_constraints_hash, comparison.unique_constraints_hash)).to eql({
            unique_constraint_name: {
              exists: true,
              column_names: {
                value: [:column_name],
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
              }
            }
          })
        end
      end

      describe "when comparison table has an equivilent unique_constraint" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :boolean
          comparison.add_unique_constraint :unique_constraint_name, [:column_name]
        end

        it "returns the expected object" do
          expect(differences_class.compare_unique_constraints(base.unique_constraints_hash, comparison.unique_constraints_hash)).to eql({
            unique_constraint_name: {
              exists: true,
              column_names: {
                value: [:column_name],
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
              }
            }
          })
        end
      end

      describe "when comparison table has a different unique_constraint" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :boolean
          comparison.add_unique_constraint :unique_constraint_name, [:column_name], deferrable: true
        end

        it "returns the expected object" do
          expect(differences_class.compare_unique_constraints(base.unique_constraints_hash, comparison.unique_constraints_hash)).to eql({
            unique_constraint_name: {
              exists: true,
              column_names: {
                value: [:column_name],
                matches: true
              },
              description: {
                value: nil,
                matches: true
              },
              deferrable: {
                value: false,
                matches: false
              },
              initially_deferred: {
                value: false,
                matches: true
              }
            }
          })
        end
      end
    end
  end
end
