# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas::Tables do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }
  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:loaded_schema) { database.add_loaded_schema :my_schema }

  describe :Columns do
    describe :migrations do
      describe "when the loaded and configured database have the same table" do
        let(:configured_table) { configured_schema.add_table :my_table }
        let(:loaded_table) { loaded_schema.add_table :my_table }

        before(:each) do
          configured_table
          loaded_table
        end

        # description is required, so there are no tests for columns without descriptions

        describe "when the configured table has a column with a description" do
          before(:each) do
            configured_table.add_column :my_column, :integer, description: "Description of my column"
          end

          it "returns the migration to create the column and description" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Additional Columns
                  #
                  add_column :my_table, :my_column, :integer, null: true, comment: <<~COMMENT
                    Description of my column
                  COMMENT
                RUBY
              }
            ])
          end

          describe "when the loaded table has a column with a different type but the same description" do
            before(:each) do
              loaded_table.add_column :my_column, :boolean, description: "Description of my column"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Update Columns
                  #
                  change_column :my_table, :my_column, :integer, null: true
                RUBY
              }])
            end
          end

          describe "when the loaded table has the same column but a different description" do
            before(:each) do
              loaded_table.add_column :my_column, :integer, description: "Different description of my column"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Update Columns
                  #
                  set_column_comment :my_table, :my_column, <<~COMMENT
                    Description of my column
                  COMMENT
                RUBY
              }])
            end
          end

          describe "when the loaded table has an equivalent column and description" do
            before(:each) do
              loaded_table.add_column :my_column, :integer, description: "Description of my column"
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
