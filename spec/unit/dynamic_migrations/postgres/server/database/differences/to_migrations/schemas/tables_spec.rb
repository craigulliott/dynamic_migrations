# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }

  describe :Tables do
    describe :migrations do
      describe "when the loaded and configured database have the same schema" do
        let(:configured_schema) { database.add_configured_schema :my_schema }
        let(:loaded_schema) { database.add_loaded_schema :my_schema }

        before(:each) do
          configured_schema
          loaded_schema
        end

        # description is required, so there are no tests for tables without descriptions

        describe "when the configured schema has a table with a description" do
          before(:each) do
            configured_schema.add_table :my_table, description: "Description of my table"
          end

          it "returns the migration to create the table and description" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :create_my_table,
                content: <<~RUBY.strip
                  #
                  # Create Table
                  #
                  table_comment = <<~COMMENT
                    Description of my table
                  COMMENT
                  create_table :my_table, id: false, comment: table_comment do |t|
                  end
                RUBY
              }
            ])
          end

          describe "when the loaded schema has the same table but a different description" do
            before(:each) do
              loaded_schema.add_table :my_table, description: "Different description of my table"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Tables
                  #
                  set_table_comment :my_table, <<~COMMENT
                    Description of my table
                  COMMENT
                RUBY
              }])
            end
          end

          describe "when the loaded schema has an equivalent table and description" do
            before(:each) do
              loaded_schema.add_table :my_table, description: "Description of my table"
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql([])
            end
          end
        end
      end
    end
  end
end
