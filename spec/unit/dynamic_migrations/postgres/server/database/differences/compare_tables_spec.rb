# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }

  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:configured_table) { configured_schema.add_table :my_table }

  let(:loaded_schema) { database.add_loaded_schema :my_schema }
  let(:loaded_table) { loaded_schema.add_table :my_table }

  describe :compare_tables do
    describe "when base schema has no tables" do
      let(:base) { configured_schema }

      describe "when comparison schema has no tables" do
        let(:comparison) { loaded_schema }

        it "returns an empty object" do
          expect(differences_class.compare_tables(base.tables_hash, comparison.tables_hash)).to eql({})
        end
      end

      describe "when comparison schema has a table" do
        let(:comparison) { loaded_schema }

        before(:each) {
          comparison.add_table :table_name
        }

        it "returns the expected object" do
          expect(differences_class.compare_tables(base.tables_hash, comparison.tables_hash)).to eql({
            table_name: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base schema has a table" do
      let(:base) { configured_schema }

      before(:each) {
        base.add_table :table_name
      }

      describe "when comparison schema has no tables" do
        let(:comparison) { loaded_schema }

        it "returns the expected object" do
          expect(differences_class.compare_tables(base.tables_hash, comparison.tables_hash)).to eql({
            table_name: {
              exists: true,
              description: {
                value: nil,
                matches: false
              },
              primary_key: {
                exists: false
              },
              columns: {},
              validations: {},
              foreign_key_constraints: {},
              unique_constraints: {}
            }
          })
        end
      end

      describe "when comparison schema has an equivilent table" do
        let(:comparison) { loaded_schema }

        before(:each) {
          comparison.add_table :table_name
        }

        it "returns the expected object" do
          expect(differences_class.compare_tables(base.tables_hash, comparison.tables_hash)).to eql({
            table_name: {
              exists: true,
              description: {
                value: nil,
                matches: true
              },
              primary_key: {
                exists: false
              },
              columns: {},
              validations: {},
              foreign_key_constraints: {},
              unique_constraints: {}
            }
          })
        end
      end

      describe "when comparison schema has a different table" do
        let(:comparison) { loaded_schema }

        before(:each) {
          comparison.add_table :table_name, "this table has a description"
        }

        it "returns the expected object" do
          expect(differences_class.compare_tables(base.tables_hash, comparison.tables_hash)).to eql({
            table_name: {
              exists: true,
              description: {
                value: nil,
                matches: false
              },
              primary_key: {
                exists: false
              },
              columns: {},
              validations: {},
              foreign_key_constraints: {},
              unique_constraints: {}
            }
          })
        end
      end
    end
  end
end
