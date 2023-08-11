# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

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
          expect(generator.add_primary_key(primary_key).to_s).to eq <<~RUBY.strip
            add_primary_key :my_table, :my_column, name: :primary_key_name
          RUBY
        end
      end

      describe "for compound unique primary_key with a custom type, order, nulls_position and a comment" do
        let(:primary_key) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column, second_column], :primary_key_name, description: "Comment for this primary_key" }

        it "should return the expected ruby syntax to add a primary_key" do
          expect(generator.add_primary_key(primary_key).to_s).to eq <<~RUBY.strip
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
          expect(generator.remove_primary_key(primary_key).to_s).to eq <<~RUBY.strip
            remove_primary_key :my_table, :primary_key_name
          RUBY
        end
      end
    end

    describe :recreate_primary_key do
      describe "for primary_keys which cover different columns" do
        let(:original_primary_key) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [column], :primary_key_name }
        let(:updated_primary_key) { DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey.new :configuration, table, [second_column], :primary_key_name }

        it "should return the expected ruby syntax to recreate a primary_key" do
          remove = <<~RUBY.strip
            # Removing original primary key because it has changed (it is recreated below)\n# Changes:
            #   column_names changed from `[:my_column]` to `[:my_second_column]`
            remove_primary_key :my_table, :primary_key_name
          RUBY
          re_add = <<~RUBY.strip
            # Recreating this primary key
            add_primary_key :my_table, :my_second_column, name: :primary_key_name
          RUBY
          expect(generator.recreate_primary_key(original_primary_key, updated_primary_key).map(&:to_s)).to eq [remove, re_add]
        end
      end
    end
  end
end
