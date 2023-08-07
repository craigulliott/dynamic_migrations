# frozen_string_literal: true

RSpec.describe DynamicMigrations::Generator do
  let(:generator) { DynamicMigrations::Generator.new }

  describe :UniqueConstraint do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }
    let(:column) { table.add_column :my_column, :integer, null: true, description: "Comment for this column" }
    let(:second_column) { table.add_column :my_second_column, :integer, null: true, description: "Comment for this column" }

    describe :add_unique_constraint do
      describe "for simple unique_constraint on one column" do
        let(:unique_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name }

        it "should return the expected ruby syntax to add a unique_constraint" do
          expect(generator.add_unique_constraint(unique_constraint)).to eq <<~RUBY
            add_unique_constraint :my_table, :my_column, name: :unique_constraint_name, deferrable: false, initially_deferred: false
          RUBY
        end
      end

      describe "for compound unique unique_constraint with a custom order, nulls_position and a comment" do
        let(:unique_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column, second_column], :unique_constraint_name, deferrable: true, initially_deferred: true, description: "Comment for this unique_constraint" }

        it "should return the expected ruby syntax to add a unique_constraint" do
          expect(generator.add_unique_constraint(unique_constraint)).to eq <<~RUBY
            add_unique_constraint :my_table, [:my_column, :my_second_column], name: :unique_constraint_name, deferrable: true, initially_deferred: true, comment: <<~COMMENT
              Comment for this unique_constraint
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_unique_constraint do
      describe "for simple unique_constraint on one column" do
        let(:unique_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name }

        it "should return the expected ruby syntax to remove a unique_constraint" do
          expect(generator.remove_unique_constraint(unique_constraint)).to eq <<~RUBY
            remove_unique_constraint :my_table, :unique_constraint_name
          RUBY
        end
      end
    end
  end
end
