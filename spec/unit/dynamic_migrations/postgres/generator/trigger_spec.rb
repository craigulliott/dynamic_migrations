# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Trigger do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:function_definition) {
      <<~SQL
        BEGIN
          NEW.column = 0;
          RETURN NEW;
        END;
      SQL
    }
    let(:function) { DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :function_name, function_definition }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }

    describe :add_trigger do
      describe "for a row based 'after update' trigger" do
        let(:trigger) { table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: function, description: "Comment for this trigger" }

        it "should return the expected short hand ruby syntax to add a trigger" do
          expect(generator.add_trigger(trigger).to_s).to eq <<~RUBY.strip
            before_insert :my_table, name: :my_trigger, function_schema_name: :my_schema, function_name: :function_name, comment: <<~COMMENT
              Comment for this trigger
            COMMENT
          RUBY
        end
      end

      describe "for a statement based 'after update' trigger" do
        let(:trigger) { table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :statement, action_timing: :before, function: function, description: "Comment for this trigger" }

        it "should return the expected ruby syntax to add a trigger" do
          expect(generator.add_trigger(trigger).to_s).to eq <<~RUBY.strip
            add_trigger :my_table, name: :my_trigger, action_timing: :before, event_manipulation: :insert, action_orientation: :statement, function_schema_name: :my_schema, function_name: :function_name, comment: <<~COMMENT
              Comment for this trigger
            COMMENT
          RUBY
        end
      end

      describe "for a trigger with parameters" do
        let(:trigger) { table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: ["true"], action_orientation: :statement, action_timing: :before, function: function, description: "Comment for this trigger" }

        it "should return the expected ruby syntax to add a trigger" do
          expect(generator.add_trigger(trigger).to_s).to eq <<~RUBY.strip
            add_trigger :my_table, name: :my_trigger, action_timing: :before, event_manipulation: :insert, action_orientation: :statement, function_schema_name: :my_schema, function_name: :function_name, parameters: ["true"], comment: <<~COMMENT
              Comment for this trigger
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_trigger do
      describe "for simple trigger" do
        let(:trigger) { table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: function }

        it "should return the expected ruby syntax to remove a trigger" do
          expect(generator.remove_trigger(trigger).to_s).to eq <<~RUBY.strip
            remove_trigger :my_table, :my_trigger
          RUBY
        end
      end
    end

    describe :recreate_trigger do
      describe "for triggers with different action_timings" do
        let(:loaded_schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :database, database, :my_schema }
        let(:loaded_table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :database, loaded_schema, :my_table, description: "Comment for this table" }
        let(:loaded_function) { loaded_schema.add_function :function_name, function_definition }
        let(:loaded_trigger) { loaded_table.add_trigger :my_trigger, event_manipulation: :insert, action_order: 1, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: loaded_function }

        let(:configured_trigger) { table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :after, function: function }

        it "should return the expected ruby syntax to recreate a trigger" do
          remove = <<~RUBY.strip
            # Removing original trigger because it has changed (it is recreated below)
            # Changes:
            #   action_timing changed from `before` to `after`
            remove_trigger :my_table, :my_trigger
          RUBY
          re_add = <<~RUBY.strip
            # Recreating this trigger
            after_insert :my_table, name: :my_trigger, function_schema_name: :my_schema, function_name: :function_name
          RUBY
          expect(generator.recreate_trigger(loaded_trigger, configured_trigger).map(&:to_s)).to eq [remove, re_add]
        end
      end
    end

    describe :set_trigger_comment do
      describe "for simple trigger" do
        let(:trigger) { table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: function, description: "My trigger comment" }

        it "should return the expected ruby syntax to set a trigger comment" do
          expect(generator.set_trigger_comment(trigger).to_s).to eq <<~RUBY.strip
            set_trigger_comment :my_table, :my_trigger, <<~COMMENT
              My trigger comment
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_trigger_comment do
      describe "for simple trigger" do
        let(:trigger) { table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: function, description: "My trigger comment" }

        it "should return the expected ruby syntax to remove a trigger comment" do
          expect(generator.remove_trigger_comment(trigger).to_s).to eq <<~RUBY.strip
            remove_trigger_comment :my_table, :my_trigger
          RUBY
        end
      end
    end
  end
end
