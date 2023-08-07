# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:function) { DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :function_name, "NEW.column = 0" }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { table.add_column :my_column, :boolean }
  let(:trigger) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function }

  describe :initialize do
    it "instantiates a new trigger without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function
      }.to_not raise_error
    end

    describe "providing an optional description" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function, description: "foo bar"
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        trigger = DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function, description: "foo bar"
        expect(trigger.description).to eq "foo bar"
      end
    end

    it "raises an error if providing an invalid table" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, :not_a_table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::ExpectedTableError
    end

    it "raises an error if providing something other than a symbol for the trigger name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, "invalid trigger name", event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    it "raises an error if providing an unexpected value for the event_manipulation" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :unexpected_value, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::UnexpectedEventManipulationError
    end

    it "raises an error if providing an unexpected value for the action_order" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: nil, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::UnexpectedActionOrderError
    end

    it "raises an error if providing an unexpected value for the action_condition" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: 123, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function
      }.to raise_error DynamicMigrations::ExpectedStringError
    end

    it "raises an error if providing an unexpected value for the action_statement" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "invalid statement", action_orientation: :row, action_timing: :before, function: function
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::UnexpectedActionStatementError
    end

    it "raises an error if providing an unexpected value for the action_orientation" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :unexpected_value, action_timing: :before, function: function
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::UnexpectedActionOrientationError
    end

    it "raises an error if providing an unexpected value for the action_timing" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :unexpected_value, function: function
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::UnexpectedActionTimingError
    end

    it "raises an error if providing an unexpected value for the function" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: nil
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::ExpectedFunctionError
    end

    it "raises an error if providing an unexpected value for the action_reference_old_table" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function, action_reference_old_table: 123
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::ExpectedOldRecordsTableError
    end

    it "raises an error if providing an unexpected value for the action_reference_new_table" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function, action_reference_new_table: 123
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger::ExpectedNewRecordsTableError
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(trigger.table).to eq(table)
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(trigger.name).to eq(:trigger_name)
    end
  end

  describe :event_manipulation do
    it "returns the expected event_manipulation" do
      expect(trigger.event_manipulation).to eq(:insert)
    end
  end

  describe :action_order do
    it "returns the expected action_order" do
      expect(trigger.action_order).to eq(1)
    end
  end

  describe :action_condition do
    it "returns the expected action_condition" do
      expect(trigger.action_condition).to eq(nil)
    end
  end

  describe :action_statement do
    it "returns the expected action_statement" do
      expect(trigger.action_statement).to eq("EXECUTE FUNCTION checklists.foo()")
    end
  end

  describe :action_orientation do
    it "returns the expected action_orientation" do
      expect(trigger.action_orientation).to eq(:row)
    end
  end

  describe :action_timing do
    it "returns the expected action_timing" do
      expect(trigger.action_timing).to eq(:before)
    end
  end

  describe :function do
    it "returns the expected function" do
      expect(trigger.function).to eq function
    end
  end

  describe :action_reference_old_table do
    describe "when no action_reference_old_table was provided at initialization" do
      it "returns nil" do
        expect(trigger.action_reference_old_table).to be_nil
      end
    end

    describe "when a action_reference_old_table was provided at initialization" do
      let(:trigger_with_action_reference_old_table) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function, action_reference_old_table: :old_records }
      it "returns the expected action_reference_old_table" do
        expect(trigger_with_action_reference_old_table.action_reference_old_table).to eq(:old_records)
      end
    end
  end

  describe :action_reference_new_table do
    describe "when no action_reference_new_table was provided at initialization" do
      it "returns nil" do
        expect(trigger.action_reference_new_table).to be_nil
      end
    end

    describe "when a action_reference_new_table was provided at initialization" do
      let(:trigger_with_action_reference_new_table) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function, action_reference_new_table: :new_records }
      it "returns the expected action_reference_new_table" do
        expect(trigger_with_action_reference_new_table.action_reference_new_table).to eq(:new_records)
      end
    end
  end

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(trigger.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:trigger_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function, description: "foo bar" }
      it "returns the expected description" do
        expect(trigger_with_description.description).to eq("foo bar")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(trigger.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:trigger_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, action_statement: "EXECUTE FUNCTION checklists.foo()", action_orientation: :row, action_timing: :before, function: function, description: "foo bar" }
      it "returns true" do
        expect(trigger_with_description.has_description?).to be(true)
      end
    end
  end
end
