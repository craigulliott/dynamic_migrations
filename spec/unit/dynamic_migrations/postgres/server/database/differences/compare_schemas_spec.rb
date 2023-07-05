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
    describe "when base has no schemas" do
      let(:base) { {} }

      describe "when comparison schema has no schemas" do
        let(:comparison) { {} }

        it "returns an empty object" do
          expect(differences_class.compare_schemas(base, comparison)).to eql({})
        end
      end

      describe "when comparison has a schema" do
        let(:comparison) { {my_schema: loaded_schema} }

        it "returns the expected object" do
          expect(differences_class.compare_schemas(base, comparison)).to eql({
            my_schema: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base has a schema" do
      let(:base) { {my_schema: configured_schema} }

      describe "when comparison has no schemas" do
        let(:comparison) { {my_schema: loaded_schema} }

        it "returns the expected object" do
          expect(differences_class.compare_schemas(base, comparison)).to eql({
            my_schema: {
              exists: true,
              tables: {}
            }
          })
        end
      end

      describe "when comparison has an equivilent schema" do
        let(:comparison) { {my_schema: loaded_schema} }

        it "returns the expected object" do
          expect(differences_class.compare_schemas(base, comparison)).to eql({
            my_schema: {
              exists: true,
              tables: {}
            }
          })
        end
      end

      describe "when comparison has a different schema" do
        let(:comparison) { {my_schema: loaded_schema} }

        before(:each) {
          comparison[:my_schema].add_table :my_table
        }

        it "returns the expected object" do
          expect(differences_class.compare_schemas(base, comparison)).to eql({
            my_schema: {
              exists: true,
              tables: {
                my_table: {
                  exists: false
                }
              }
            }
          })
        end
      end
    end
  end
end
