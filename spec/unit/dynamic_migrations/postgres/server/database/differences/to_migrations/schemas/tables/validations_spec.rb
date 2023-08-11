# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas::Tables do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }
  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:loaded_schema) { database.add_loaded_schema :my_schema }

  describe :Validations do
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

        describe "when the configured table has a validation" do
          before(:each) do
            configured_table.add_validation :my_validation, [:my_column], "my_column > 0"
          end

          it "returns the migration to create the validation" do
            expect(to_migrations.migrations).to eql({
              my_schema: [
                {
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Validations
                    #
                    add_validation :my_table, name: :my_validation, deferrable: false, initially_deferred: false do
                      <<~SQL
                        my_column > 0;
                      SQL
                    end
                  RUBY
                }
              ]
            })
          end

          describe "when the loaded table has a validation with the same name but a different check clause" do
            before(:each) do
              loaded_table.add_validation :my_validation, [:my_column], "my_column > 100"
            end

            it "returns the migration to update the validation by replacing it" do
              expect(to_migrations.migrations).to eql({
                my_schema: [
                  {
                    name: :changes_for_my_table,
                    content: <<~RUBY.strip
                      #
                      # Remove Validations
                      #
                      # Removing original validation because it has changed (it is recreated below)
                      # Changes:
                      #   check_clause changed from `my_column > 100` to `my_column > 0`
                      remove_validation :my_table, :my_validation
                    RUBY
                  },
                  {
                    name: :changes_for_my_table,
                    content: <<~RUBY.strip
                      #
                      # Validations
                      #
                      # Recreating this validation
                      add_validation :my_table, name: :my_validation, deferrable: false, initially_deferred: false do
                        <<~SQL
                          my_column > 0;
                        SQL
                      end
                    RUBY
                  }
                ]
              })
            end
          end

          describe "when the loaded table has an equivalent validation" do
            before(:each) do
              loaded_table.add_validation :my_validation, [:my_column], "my_column > 0"
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql({})
            end
          end
        end

        describe "when the configured table has a validation with a description" do
          before(:each) do
            configured_table.add_validation :my_validation, [:my_column], "my_column > 0", description: "Description of my validation"
          end

          it "returns the migration to create the validation and description" do
            expect(to_migrations.migrations).to eql({
              my_schema: [
                {
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Validations
                    #
                    my_validation_comment = <<~COMMENT
                      Description of my validation
                    COMMENT
                    add_validation :my_table, name: :my_validation, deferrable: false, initially_deferred: false, comment: my_validation_comment do
                      <<~SQL
                        my_column > 0;
                      SQL
                    end
                  RUBY
                }
              ]
            })
          end

          describe "when the loaded table has the same validation but a different description" do
            before(:each) do
              loaded_table.add_validation :my_validation, [:my_column], "my_column > 0", description: "Different description of my table"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql({
                my_schema: [{
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Validations
                    #
                    set_validation_comment :my_table, :my_validation, <<~COMMENT
                      Description of my validation
                    COMMENT
                  RUBY
                }]
              })
            end
          end

          describe "when the loaded table has an equivalent validation and description" do
            before(:each) do
              loaded_table.add_validation :my_validation, [:my_column], "my_column > 0", description: "Description of my validation"
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
