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

  describe :compare_schemas do
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
        let(:comparison) { {} }

        it "returns the expected object" do
          expect(differences_class.compare_schemas(base, comparison)).to eql({
            my_schema: {
              exists: true,
              tables: {},
              functions: {},
              enums: {}
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
              tables: {},
              enums: {},
              functions: {}
            }
          })
        end
      end

      describe "when comparison has a different schema (a schema with a function in it)" do
        let(:comparison) { {my_schema: loaded_schema} }

        before(:each) do
          comparison[:my_schema].add_table :my_table
          comparison[:my_schema].add_function :my_function, <<~SQL
            BEGIN
              NEW.column = 0;
              RETURN NEW;
            END;
          SQL
        end

        it "returns the expected object" do
          expect(differences_class.compare_schemas(base, comparison)).to eql({
            my_schema: {
              exists: true,
              tables: {
                my_table: {
                  exists: false
                }
              },
              functions: {
                my_function: {
                  exists: false
                }
              },
              enums: {}
            }
          })
        end
      end
    end
  end
end
