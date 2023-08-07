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

  describe :compare_table do
    describe "when base is nil" do
      let(:base) { nil }

      describe "when comparison is nil" do
        let(:comparison) { nil }

        it "raises an error, because base is required" do
          expect {
            differences_class.compare_table(base, comparison)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Differences::TableRequiredError
        end
      end

      describe "when comparison is a table" do
        let(:comparison) { loaded_table }

        it "raises an error, because base is required" do
          expect {
            differences_class.compare_table(base, comparison)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Differences::TableRequiredError
        end
      end
    end

    describe "when base is a table" do
      let(:base) { configured_table }

      describe "when comparison is nil" do
        let(:comparison) { nil }

        it "returns the expected object" do
          expect(differences_class.compare_table(base, comparison)).to eql({
            exists: true,
            description: {
              value: nil,
              matches: false
            },
            primary_key: {
              exists: false
            },
            columns: {},
            triggers: {},
            validations: {},
            foreign_key_constraints: {},
            unique_constraints: {}
          })
        end
      end

      describe "when comparison is an equivilent table" do
        let(:comparison) { loaded_table }

        it "returns the expected object" do
          expect(differences_class.compare_table(base, comparison)).to eql({
            exists: true,
            description: {
              value: nil,
              matches: true
            },
            primary_key: {
              exists: false
            },
            columns: {},
            triggers: {},
            validations: {},
            foreign_key_constraints: {},
            unique_constraints: {}
          })
        end
      end

      describe "when comparison is a different table" do
        let(:comparison) { loaded_schema.add_table :my_table, description: "a different description" }

        it "returns the expected object" do
          expect(differences_class.compare_table(base, comparison)).to eql({
            exists: true,
            description: {
              value: nil,
              matches: false
            },
            primary_key: {
              exists: false
            },
            columns: {},
            triggers: {},
            validations: {},
            foreign_key_constraints: {},
            unique_constraints: {}
          })
        end
      end
    end
  end
end
