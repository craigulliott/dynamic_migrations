# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :ConfiguredExtensions do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :add_configured_extension do
      it "creates a new extension" do
        database.add_configured_extension(:extension_name)
        expect(database.has_configured_extension?(:extension_name)).to be true
      end

      it "raises an error if providing an invalid extension name" do
        expect {
          database.add_configured_extension "my_database"
        }.to raise_error DynamicMigrations::ExpectedSymbolError
      end

      describe "when a extension already exists" do
        before(:each) do
          database.add_configured_extension(:extension_name)
        end

        it "raises an error if using the same extension name" do
          expect {
            database.add_configured_extension(:extension_name)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::ConfiguredExtensionAlreadyExistsError
        end
      end
    end

    describe :has_configured_extension? do
      it "returns false" do
        expect(database.has_configured_extension?(:configured_extension)).to be(false)
      end

      describe "after the expected configured_extension has been added" do
        let(:configured_extension) { database.add_configured_extension :configured_extension }

        before(:each) do
          configured_extension
        end

        it "returns true" do
          expect(database.has_configured_extension?(:configured_extension)).to be(true)
        end
      end
    end

    describe :configured_extensions do
      it "returns an empty array" do
        expect(database.configured_extensions).to be_an Array
        expect(database.configured_extensions).to be_empty
      end

      describe "after the expected extension has been added" do
        let(:extension) { database.add_configured_extension :extension_name }

        before(:each) do
          extension
        end

        it "returns an array of the expected extensions" do
          expect(database.configured_extensions).to eql([:extension_name])
        end
      end
    end
  end
end
