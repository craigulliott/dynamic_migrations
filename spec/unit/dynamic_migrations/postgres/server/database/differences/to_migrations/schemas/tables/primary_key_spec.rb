# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas::Tables do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }
  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:loaded_schema) { database.add_loaded_schema :my_schema }

  describe :PrimaryKey do
    describe :migrations do
      describe "when the loaded and configured database have the same table and column" do
        let(:configured_table) { configured_schema.add_table :my_table }
        let(:configured_column) { configured_table.add_column :my_column, :integer }

        let(:loaded_table) { loaded_schema.add_table :my_table }
        let(:loaded_column) { loaded_table.add_column :my_column, :integer }

        before(:each) do
          configured_column
          loaded_column
        end

        describe "when the configured table has a primary_key" do
          before(:each) do
            configured_table.add_primary_key :my_primary_key, [:my_column]
          end

          it "returns the migration to create the primary_key" do
            expect(to_migrations.migrations).to eql({
              my_schema: [
                {
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Primary Key
                    #
                    add_primary_key :my_table, :my_column, name: :my_primary_key
                  RUBY
                }
              ]
            })
          end

          describe "when the loaded table has a primary_key on a different column" do
            before(:each) do
              # add the additional column on both so that there are no column differences
              configured_table.add_column :my_other_column, :integer
              loaded_table.add_column :my_other_column, :integer
              # add the loaded primary_key across two columns, so that the primary_keyes are different
              loaded_table.add_primary_key :my_primary_key, [:my_other_column]
            end

            it "returns the migration to update the primary_key by replacing it" do
              expect(to_migrations.migrations).to eql({
                my_schema: [
                  {
                    name: :changes_for_my_table,
                    content: <<~RUBY.strip
                      #
                      # Remove Primary Keys
                      #
                      # Removing original primary key because it has changed (it is recreated below)
                      # Changes:
                      #   column_names changed from `[:my_other_column]` to `[:my_column]`
                      remove_primary_key :my_table, :my_primary_key
                    RUBY
                  },
                  {
                    name: :changes_for_my_table,
                    content: <<~RUBY.strip
                      #
                      # Primary Key
                      #
                      # Recreating this primary key
                      add_primary_key :my_table, :my_column, name: :my_primary_key
                    RUBY
                  }
                ]
              })
            end
          end

          describe "when the loaded table has an equivalent primary_key" do
            before(:each) do
              loaded_table.add_primary_key :my_primary_key, [:my_column]
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql({})
            end
          end
        end
      end
    end
  end
end
