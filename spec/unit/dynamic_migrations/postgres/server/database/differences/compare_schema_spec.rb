# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

  let(:configured_schema) { database.add_configured_schema :my_schema }

  let(:loaded_schema) { database.add_loaded_schema :my_schema }

  describe :compare_schema do
    describe "when base is nil" do
      let(:base) { nil }

      describe "when comparison is nil" do
        let(:comparison) { nil }

        it "raises an error, because base is required" do
          expect {
            differences_class.compare_schema(base, comparison)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Differences::SchemaRequiredError
        end
      end

      describe "when comparison is a schema" do
        let(:comparison) { loaded_schema }

        it "raises an error, because base is required" do
          expect {
            differences_class.compare_schema(base, comparison)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Differences::SchemaRequiredError
        end
      end
    end

    describe "when base is a schema" do
      let(:base) { configured_schema }

      describe "when comparison is nil" do
        let(:comparison) { nil }

        it "returns the expected object" do
          expect(differences_class.compare_schema(base, comparison)).to eql({
            exists: true,
            tables: {},
            enums: {},
            functions: {}
          })
        end
      end

      describe "when comparison is an equivilent schema" do
        let(:comparison) { loaded_schema }

        it "returns the expected object" do
          expect(differences_class.compare_schema(base, comparison)).to eql({
            exists: true,
            tables: {},
            enums: {},
            functions: {}
          })
        end
      end

      describe "when comparison is a different schema" do
        let(:comparison) { loaded_schema }

        before(:each) do
          comparison.add_table :my_table
          comparison.add_function :my_function, <<~SQL
            BEGIN
              NEW.column = 0;
              RETURN NEW;
            END;
          SQL
        end

        it "returns the expected object" do
          expect(differences_class.compare_schema(base, comparison)).to eql({
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
          })
        end
      end
    end
  end
end
