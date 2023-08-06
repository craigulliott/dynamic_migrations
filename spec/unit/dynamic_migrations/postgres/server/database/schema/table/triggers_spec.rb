# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }

  describe :Triggers do
    describe :add_trigger do
      before(:each) do
        table.add_column :column_name, :boolean
      end

      it "creates a new trigger object" do
        expect(table.add_trigger(:trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function_schema: :my_schemam, function_name: :my_function, function_definition: "SQL")).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger
      end

      describe "when a trigger already exists" do
        before(:each) do
          table.add_trigger(:trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function_schema: :my_schemam, function_name: :my_function, function_definition: "SQL")
        end

        it "raises an error if using the same trigger name" do
          expect {
            table.add_trigger(:trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function_schema: :my_schemam, function_name: :my_function, function_definition: "SQL")
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::TriggerAlreadyExistsError
        end
      end
    end

    describe :trigger do
      it "raises an error" do
        expect {
          table.trigger(:trigger_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::TriggerDoesNotExistError
      end

      describe "after the expected trigger has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:trigger) { table.add_trigger :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function_schema: :my_schemam, function_name: :my_function, function_definition: "SQL" }

        before(:each) do
          column
          trigger
        end

        it "returns the trigger" do
          expect(table.trigger(:trigger_name)).to eq(trigger)
        end
      end
    end

    describe :has_trigger? do
      it "returns false" do
        expect(table.has_trigger?(:trigger_name)).to be(false)
      end

      describe "after the expected trigger has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:trigger) { table.add_trigger :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function_schema: :my_schemam, function_name: :my_function, function_definition: "SQL" }

        before(:each) do
          column
          trigger
        end

        it "returns true" do
          expect(table.has_trigger?(:trigger_name)).to be(true)
        end
      end
    end

    describe :triggers do
      it "returns an empty array" do
        expect(table.triggers).to be_an Array
        expect(table.triggers).to be_empty
      end

      describe "after the expected trigger has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:trigger) { table.add_trigger :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function_schema: :my_schemam, function_name: :my_function, function_definition: "SQL" }

        before(:each) do
          column
          trigger
        end

        it "returns an array of the expected triggers" do
          expect(table.triggers).to eql([trigger])
        end
      end
    end

    describe :triggers_hash do
      it "returns an empty object" do
        expect(table.triggers_hash).to eql({})
      end

      describe "after the expected trigger has been added" do
        let(:column) { table.add_column :column_name, :boolean }
        let(:trigger) { table.add_trigger :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function_schema: :my_schemam, function_name: :my_function, function_definition: "SQL" }

        before(:each) do
          column
          trigger
        end

        it "returns a hash representation of the expected triggers" do
          expect(table.triggers_hash).to eql({trigger_name: trigger})
        end
      end
    end
  end
end
