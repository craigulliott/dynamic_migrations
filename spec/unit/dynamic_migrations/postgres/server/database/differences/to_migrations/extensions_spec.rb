# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }

  describe :Extensions do
    describe :migrations do
      describe "when the configured database has an extension" do
        before(:each) do
          database.add_configured_extension :my_extension
        end

        it "returns the migration to create it" do
          expect(to_migrations.migrations).to eql([{
            schema_name: nil,
            name: :create_my_extension_extension,
            content: <<~RUBY.strip
              #
              # Create Extension
              #
              create_extension :my_extension
            RUBY
          }])
        end

        describe "when the loaded database has an equivalent extension" do
          before(:each) do
            database.add_loaded_extension :my_extension
          end

          it "returns no migrations because there are no differences" do
            expect(to_migrations.migrations).to eql([])
          end
        end
      end

      describe "when the loaded database has an extension" do
        before(:each) do
          database.add_loaded_extension :my_extension
        end

        it "returns the migration to delete it, because the configured does not have it" do
          expect(to_migrations.migrations).to eql([{
            schema_name: nil,
            name: :drop_my_extension_extension,
            content: <<~RUBY.strip
              #
              # Drop Extension
              #
              drop_extension :my_extension
            RUBY
          }])
        end
      end
    end
  end
end
