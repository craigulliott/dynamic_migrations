# frozen_string_literal: true

RSpec.describe DynamicMigrations::Generator do
  let(:generator) { DynamicMigrations::Generator.new }

  describe :PrimaryKey do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }
    let(:column) { table.add_column :my_column, :integer, null: true, description: "Comment for this column" }
    let(:second_column) { table.add_column :my_second_column, :integer, null: true, description: "Comment for this column" }

    describe :add_primary_key do
      describe "for simple primary_key on one column" do
        let(:primary_key) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name }

        it "should return the expected ruby syntax to add a primary_key" do
          expect(generator.add_primary_key(primary_key)).to eq <<~RUBY
            add_primary_key :my_table, :my_column, name: :primary_key_name
          RUBY
        end
      end

      describe "for compound unique primary_key with a custom type, order, nulls_position and a comment" do
        let(:primary_key) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column, second_column], :primary_key_name, description: "Comment for this primary_key" }

        it "should return the expected ruby syntax to add a primary_key" do
          expect(generator.add_primary_key(primary_key)).to eq <<~RUBY
            add_primary_key :my_table, [:my_column, :my_second_column], name: :primary_key_name, comment: <<~COMMENT
              Comment for this primary_key
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_primary_key do
      describe "for simple primary_key on one column" do
        let(:primary_key) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name }

        it "should return the expected ruby syntax to remove a primary_key" do
          expect(generator.remove_primary_key(primary_key)).to eq <<~RUBY
            remove_primary_key :my_table, :primary_key_name
          RUBY
        end
      end
    end
  end
end
