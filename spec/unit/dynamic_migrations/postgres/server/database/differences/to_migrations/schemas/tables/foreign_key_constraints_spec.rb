# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas::Tables do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }
  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:loaded_schema) { database.add_loaded_schema :my_schema }

  describe :ForeignKeyConstraints do
    describe :migrations do
      describe "when the loaded and configured database have the same table and column" do
        let(:configured_table) { configured_schema.add_table :my_table }
        let(:configured_column) { configured_table.add_column :my_column, :integer }
        let(:configured_foreign_table) { configured_schema.add_table :my_foreign_table }
        let(:configured_foreign_column) { configured_foreign_table.add_column :my_foreign_column, :integer }

        let(:loaded_table) { loaded_schema.add_table :my_table }
        let(:loaded_column) { loaded_table.add_column :my_column, :integer }
        let(:loaded_foreign_table) { loaded_schema.add_table :my_foreign_table }
        let(:loaded_foreign_column) { loaded_foreign_table.add_column :my_foreign_column, :integer }

        before(:each) do
          configured_column
          loaded_column
          configured_foreign_column
          loaded_foreign_column
        end

        describe "when the configured table has a foreign_key" do
          before(:each) do
            configured_table.add_foreign_key_constraint :my_foreign_key, [configured_column.name], configured_foreign_table.schema.name, configured_foreign_table.name, [configured_foreign_column.name]
          end

          it "returns the migration to create the foreign_key" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Foreign Keys
                  #
                  add_foreign_key :my_table, :my_column, :my_foreign_table, :my_foreign_column, name: :my_foreign_key
                RUBY
              }
            ])
          end

          describe "when the loaded table has a foreign_key with the same name but a different deferrable value" do
            before(:each) do
              loaded_table.add_foreign_key_constraint :my_foreign_key, [loaded_column.name], loaded_foreign_table.schema.name, loaded_foreign_table.name, [loaded_foreign_column.name], deferrable: true
            end

            it "returns the migration to update the foreign_key by replacing it" do
              expect(to_migrations.migrations).to eql([
                {
                  schema_name: :my_schema,
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Remove Foreign Keys
                    #
                    # Removing original foreign key constraint because it has changed (it is recreated below)
                    # Changes:
                    #   deferrable changed from `true` to `false`
                    remove_foreign_key :my_table, :my_foreign_key

                    #
                    # Foreign Keys
                    #
                    # Recreating this foreign key constraint
                    add_foreign_key :my_table, :my_column, :my_foreign_table, :my_foreign_column, name: :my_foreign_key
                  RUBY
                }
              ])
            end
          end

          describe "when the loaded table has an equivalent foreign_key" do
            before(:each) do
              loaded_table.add_foreign_key_constraint :my_foreign_key, [loaded_column.name], loaded_foreign_table.schema.name, loaded_foreign_table.name, [loaded_foreign_column.name]
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql([])
            end
          end
        end

        describe "when the configured table has a foreign_key with a description" do
          before(:each) do
            configured_table.add_foreign_key_constraint :my_foreign_key, [configured_column.name], configured_foreign_table.schema.name, configured_foreign_table.name, [configured_foreign_column.name], description: "Description of my foreign_key"
          end

          it "returns the migration to create the foreign_key and description" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Foreign Keys
                  #
                  add_foreign_key :my_table, :my_column, :my_foreign_table, :my_foreign_column, name: :my_foreign_key, comment: <<~COMMENT
                    Description of my foreign_key
                  COMMENT
                RUBY
              }
            ])
          end

          describe "when the loaded table has the same foreign_key but a different description" do
            before(:each) do
              loaded_table.add_foreign_key_constraint :my_foreign_key, [loaded_column.name], loaded_foreign_table.schema.name, loaded_foreign_table.name, [loaded_foreign_column.name], description: "Different description of my foreign_key"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Foreign Keys
                  #
                  set_foreign_key_comment :my_table, :my_foreign_key, <<~COMMENT
                    Description of my foreign_key
                  COMMENT
                RUBY
              }])
            end
          end

          describe "when the loaded table has an equivalent foreign_key and description" do
            before(:each) do
              loaded_table.add_foreign_key_constraint :my_foreign_key, [loaded_column.name], loaded_foreign_table.schema.name, loaded_foreign_table.name, [loaded_foreign_column.name], description: "Description of my foreign_key"
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
