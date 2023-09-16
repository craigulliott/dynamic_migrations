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

  describe :compare_validations do
    describe "when base table has no validations" do
      let(:base) { configured_table }

      describe "when comparison table has no validations" do
        let(:comparison) { loaded_table }

        it "returns an empty object" do
          expect(differences_class.compare_validations(base.validations_hash, comparison.validations_hash)).to eql({})
        end
      end

      describe "when comparison table has a validation" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :boolean
          comparison.add_validation :validation_name, [:column_name], "(column_name IS TRUE)"
        end

        it "returns the expected object" do
          expect(differences_class.compare_validations(base.validations_hash, comparison.validations_hash)).to eql({
            validation_name: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base table has a validation" do
      let(:base) { configured_table }

      before(:each) do
        base.add_column :column_name, :boolean
        base.add_validation :validation_name, [:column_name], "(column_name IS TRUE)"
      end

      describe "when comparison table has no validations" do
        let(:comparison) { loaded_table }

        it "returns the expected object" do
          expect(differences_class.compare_validations(base.validations_hash, comparison.validations_hash)).to eql({
            validation_name: {
              exists: true,
              normalized_check_clause: {
                value: "(column_name IS TRUE)",
                matches: false
              },
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

      describe "when comparison table has an equivilent validation" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :boolean
          comparison.add_validation :validation_name, [:column_name], "(column_name IS TRUE)"
        end

        it "returns the expected object" do
          expect(differences_class.compare_validations(base.validations_hash, comparison.validations_hash)).to eql({
            validation_name: {
              exists: true,
              normalized_check_clause: {
                value: "(column_name IS TRUE)",
                matches: true
              },
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

      describe "when comparison table has a different validation" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :boolean
          comparison.add_validation :validation_name, [:column_name], "(column_name IS FALSE)"
        end

        it "returns the expected object" do
          expect(differences_class.compare_validations(base.validations_hash, comparison.validations_hash)).to eql({
            validation_name: {
              exists: true,
              normalized_check_clause: {
                value: "(column_name IS TRUE)",
                matches: false
              },
              description: {
                value: nil,
                matches: true
              },
              column_names: {
                value: [:column_name],
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
    end
  end
end
