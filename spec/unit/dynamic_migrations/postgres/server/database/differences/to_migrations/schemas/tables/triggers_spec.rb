# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas::Tables do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }
  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:loaded_schema) { database.add_loaded_schema :my_schema }

  describe :Triggers do
    describe :migrations do
      describe "when the loaded and configured database have the same function, table and column" do
        let(:configured_function) {
          configured_schema.add_function :my_function, <<~SQL
            BEGIN
              NEW.column = 0;
              RETURN NEW;
            END;
          SQL
        }
        let(:configured_table) { configured_schema.add_table :my_table }
        let(:configured_column) { configured_table.add_column :my_column, :integer }

        let(:loaded_function) {
          loaded_schema.add_function :my_function, <<~SQL
            BEGIN
              NEW.column = 0;
              RETURN NEW;
            END;
          SQL
        }
        let(:loaded_table) { loaded_schema.add_table :my_table }
        let(:loaded_column) { loaded_table.add_column :my_column, :integer }

        before(:each) do
          configured_column
          configured_function

          loaded_column
          loaded_function
        end

        describe "when the configured table has a trigger" do
          before(:each) do
            configured_table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: nil, action_orientation: :row, action_timing: :before, function: configured_function
          end

          it "returns the migration to create the trigger" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Triggers
                  #
                  before_insert :my_table, name: :my_trigger, function_schema_name: :my_schema, function_name: :my_function
                RUBY
              }
            ])
          end

          describe "when the loaded table has a trigger with the same name but a different action_timing" do
            before(:each) do
              loaded_table.add_trigger :my_trigger, event_manipulation: :insert, action_order: 1, action_condition: nil, parameters: nil, action_orientation: :row, action_timing: :after, function: loaded_function
            end

            it "returns the migration to update the trigger by replacing it" do
              expect(to_migrations.migrations).to eql([
                {
                  schema_name: :my_schema,
                  name: :changes_for_my_table,
                  content: <<~RUBY.strip
                    #
                    # Remove Triggers
                    #
                    # Removing original trigger because it has changed (it is recreated below)
                    # Changes:
                    #   action_timing changed from `after` to `before`
                    remove_trigger :my_table, :my_trigger

                    #
                    # Triggers
                    #
                    # Recreating this trigger
                    before_insert :my_table, name: :my_trigger, function_schema_name: :my_schema, function_name: :my_function
                  RUBY
                }
              ])
            end
          end

          describe "when the loaded table has an equivalent trigger" do
            before(:each) do
              loaded_table.add_trigger :my_trigger, event_manipulation: :insert, action_order: 1, action_condition: nil, parameters: nil, action_orientation: :row, action_timing: :before, function: loaded_function
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql([])
            end
          end
        end

        describe "when the configured table has a trigger with a description" do
          before(:each) do
            configured_table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: nil, action_orientation: :row, action_timing: :before, function: configured_function, description: "Description of my trigger"
          end

          it "returns the migration to create the trigger and description" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Triggers
                  #
                  before_insert :my_table, name: :my_trigger, function_schema_name: :my_schema, function_name: :my_function, comment: <<~COMMENT
                    Description of my trigger
                  COMMENT
                RUBY
              }
            ])
          end

          describe "when the loaded table has the same trigger but a different description" do
            before(:each) do
              loaded_table.add_trigger :my_trigger, event_manipulation: :insert, action_order: 1, action_condition: nil, parameters: nil, action_orientation: :row, action_timing: :before, function: loaded_function, description: "Different description of my trigger"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Triggers
                  #
                  set_trigger_comment :my_table, :my_trigger, <<~COMMENT
                    Description of my trigger
                  COMMENT
                RUBY
              }])
            end
          end

          describe "when the loaded table has an equivalent trigger and description" do
            before(:each) do
              loaded_table.add_trigger :my_trigger, event_manipulation: :insert, action_order: 1, action_condition: nil, parameters: nil, action_orientation: :row, action_timing: :before, function: loaded_function, description: "Description of my trigger"
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
