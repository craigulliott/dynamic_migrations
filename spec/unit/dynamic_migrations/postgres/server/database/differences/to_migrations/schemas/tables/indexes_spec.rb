# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas::Tables do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }
  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:loaded_schema) { database.add_loaded_schema :my_schema }

  describe :Indexes do
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

        describe "when the configured table has a index" do
          before(:each) do
            configured_table.add_index :my_index, [:my_column]
          end

          it "returns the migration to create the index" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Indexes
                  #
                  add_index :my_table, :my_column, name: :my_index, unique: false, using: :btree, sort: :asc
                RUBY
              }
            ])
          end

          describe "when the loaded table has a index with the same name but a different order" do
            before(:each) do
              loaded_table.add_index :my_index, [:my_column], order: :desc
            end

            it "returns the migration to update the index by replacing it" do
              expect(to_migrations.migrations).to eql([
                {
                  schema_name: :my_schema,
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Remove Indexes
                    #
                    # Removing original index because it has changed (it is recreated below)
                    # Changes:
                    #   order changed from `desc` to `asc`
                    remove_index :my_table, :my_index

                    #
                    # Indexes
                    #
                    # Recreating this index
                    add_index :my_table, :my_column, name: :my_index, unique: false, using: :btree, sort: :asc
                  RUBY
                }
              ])
            end
          end

          describe "when the loaded table has a index with the same name but across additional columns" do
            before(:each) do
              # add the additional column on both so that there are no column differences
              configured_table.add_column :my_other_column, :integer
              loaded_table.add_column :my_other_column, :integer
              # add the loaded index across two columns, so that the indexes are different
              loaded_table.add_index :my_index, [:my_column, :my_other_column]
            end

            it "returns the migration to update the index by replacing it" do
              expect(to_migrations.migrations).to eql([
                {
                  schema_name: :my_schema,
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Remove Indexes
                    #
                    # Removing original index because it has changed (it is recreated below)
                    # Changes:
                    #   column_names changed from `[:my_column, :my_other_column]` to `[:my_column]`
                    remove_index :my_table, :my_index

                    #
                    # Indexes
                    #
                    # Recreating this index
                    add_index :my_table, :my_column, name: :my_index, unique: false, using: :btree, sort: :asc
                  RUBY
                }
              ])
            end
          end

          describe "when the loaded table has an equivalent index" do
            before(:each) do
              loaded_table.add_index :my_index, [:my_column]
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql([])
            end
          end
        end

        describe "when the configured table has a index with a description" do
          before(:each) do
            configured_table.add_index :my_index, [:my_column], description: "Description of my index"
          end

          it "returns the migration to create the index and description" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Indexes
                  #
                  add_index :my_table, :my_column, name: :my_index, unique: false, using: :btree, sort: :asc, comment: <<~COMMENT
                    Description of my index
                  COMMENT
                RUBY
              }
            ])
          end

          describe "when the loaded table has the same index but a different description" do
            before(:each) do
              loaded_table.add_index :my_index, [:my_column], description: "Different description of my index"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Indexes
                  #
                  set_index_comment :my_table, :my_index, <<~COMMENT
                    Description of my index
                  COMMENT
                RUBY
              }])
            end
          end

          describe "when the loaded table has an equivalent index and description" do
            before(:each) do
              loaded_table.add_index :my_index, [:my_column], description: "Description of my index"
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
