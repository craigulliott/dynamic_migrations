# frozen_string_literal: true

RSpec.describe DynamicMigrations::Generator do
  let(:generator) { DynamicMigrations::Generator.new }

  describe :ForeignKeyConstraint do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { database.add_configured_schema :my_schema }
    let(:table) { schema.add_table :my_table, "Comment for this table" }
    let(:column) { table.add_column :my_column, :boolean }
    let(:second_column) { table.add_column :my_second_column, :boolean }
    let(:foreign_table) { schema.add_table :my_foreign_table }
    let(:foreign_column) { foreign_table.add_column :my_foreign_column, :boolean }
    let(:second_foreign_column) { foreign_table.add_column :my_second_foreign_column, :boolean }

    before(:each) do
      column
      second_column
      foreign_column
      second_foreign_column
    end

    describe :add_foreign_key_constraint do
      describe "for simple foreign_key_constraint on one column" do
        let(:foreign_key_constraint) { table.add_foreign_key_constraint :foreign_key_constraint_name, [:my_column], :my_schema, :my_foreign_table, [:my_foreign_column] }

        it "should return the expected ruby syntax to add a foreign_key_constraint" do
          expect(generator.add_foreign_key_constraint(foreign_key_constraint)).to eq <<~RUBY
            add_foreign_key_constraint :my_table, :my_column, :my_foreign_table, :my_foreign_column, name: :foreign_key_constraint_name, initially_deferred: false, deferrable: false, on_delete: :no_action, on_update: :no_action
          RUBY
        end
      end

      describe "for composite foreign_key_constraint which is initially deferred, has a non default on_delete and on_update and has a comment" do
        let(:foreign_key_constraint) { table.add_foreign_key_constraint :foreign_key_constraint_name, [:my_column, :my_second_column], :my_schema, :my_foreign_table, [:my_foreign_column, :my_second_foreign_column], initially_deferred: true, deferrable: true, on_delete: :cascade, on_update: :cascade, description: "Comment for this foreign_key_constraint" }

        it "should return the expected ruby syntax to add a foreign_key_constraint" do
          expect(generator.add_foreign_key_constraint(foreign_key_constraint)).to eq <<~RUBY
            add_foreign_key_constraint :my_table, [:my_column, :my_second_column], :my_foreign_table, [:my_foreign_column, :my_second_foreign_column], name: :foreign_key_constraint_name, initially_deferred: true, deferrable: true, on_delete: :cascade, on_update: :cascade, comment: <<~COMMENT
              Comment for this foreign_key_constraint
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_foreign_key_constraint do
      describe "for simple foreign_key_constraint on one column" do
        let(:foreign_key_constraint) { table.add_foreign_key_constraint :foreign_key_constraint_name, [:my_column], :my_schema, :my_foreign_table, [:my_foreign_column] }

        it "should return the expected ruby syntax to remove a foreign_key_constraint" do
          expect(generator.remove_foreign_key_constraint(foreign_key_constraint)).to eq <<~RUBY
            remove_foreign_key :my_table, :foreign_key_constraint_name
          RUBY
        end
      end
    end
  end
end
