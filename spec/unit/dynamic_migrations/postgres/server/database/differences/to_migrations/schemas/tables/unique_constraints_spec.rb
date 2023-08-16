# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas::Tables do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }
  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:loaded_schema) { database.add_loaded_schema :my_schema }

  describe :UniqueConstraints do
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

        describe "when the configured table has a unique_constraint" do
          before(:each) do
            configured_table.add_unique_constraint :my_unique_constraint, [:my_column]
          end

          it "returns the migration to create the unique_constraint" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Validations
                  #
                  add_unique_constraint :my_table, :my_column, name: :my_unique_constraint, deferrable: false, initially_deferred: false
                RUBY
              }
            ])
          end

          describe "when the loaded table has a unique_constraint with the same name but a different deffereable value" do
            before(:each) do
              loaded_table.add_unique_constraint :my_unique_constraint, [:my_column], deferrable: true
            end

            it "returns the migration to update the unique_constraint by replacing it" do
              expect(to_migrations.migrations).to eql([
                {
                  schema_name: :my_schema,
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Remove Validations
                    #
                    # Removing original unique constraint because it has changed (it is recreated below)
                    # Changes:
                    #   deferrable changed from `true` to `false`
                    remove_unique_constraint :my_table, :my_unique_constraint

                    #
                    # Validations
                    #
                    # Recreating this unique constraint
                    add_unique_constraint :my_table, :my_column, name: :my_unique_constraint, deferrable: false, initially_deferred: false
                  RUBY
                }
              ])
            end
          end

          describe "when the loaded table has an equivalent unique_constraint" do
            before(:each) do
              loaded_table.add_unique_constraint :my_unique_constraint, [:my_column]
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql([])
            end
          end
        end

        describe "when the configured table has a unique_constraint with a description" do
          before(:each) do
            configured_table.add_unique_constraint :my_unique_constraint, [:my_column], description: "Description of my unique_constraint"
          end

          it "returns the migration to create the unique_constraint and description" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Validations
                  #
                  add_unique_constraint :my_table, :my_column, name: :my_unique_constraint, deferrable: false, initially_deferred: false, comment: <<~COMMENT
                    Description of my unique_constraint
                  COMMENT
                RUBY
              }
            ])
          end

          describe "when the loaded table has the same unique_constraint but a different description" do
            before(:each) do
              loaded_table.add_unique_constraint :my_unique_constraint, [:my_column], description: "Different description of my table"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Validations
                  #
                  set_unique_constraint_comment :my_table, :my_unique_constraint, <<~COMMENT
                    Description of my unique_constraint
                  COMMENT
                RUBY
              }])
            end
          end

          describe "when the loaded table has an equivalent unique_constraint and description" do
            before(:each) do
              loaded_table.add_unique_constraint :my_unique_constraint, [:my_column], description: "Description of my unique_constraint"
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
