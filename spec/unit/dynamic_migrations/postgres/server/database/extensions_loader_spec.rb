# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :ExtensionsLoader do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :fetch_extensions do
      it "raises an error" do
        expect {
          database.fetch_extensions
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty array" do
          expect(database.fetch_extensions).to_not include :citext
        end

        describe "after an extension has been created" do
          before :each do
            pg_helper.create_extension :citext
          end

          after :each do
            pg_helper.drop_extension :citext
          end

          it "returns the expected extension in the array" do
            expect(database.fetch_extensions).to include :citext
          end
        end
      end
    end
  end
end
