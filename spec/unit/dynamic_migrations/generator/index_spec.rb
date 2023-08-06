# frozen_string_literal: true

RSpec.describe DynamicMigrations::Generator do
  let(:generator) { DynamicMigrations::Generator.new }

  describe :Index do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }
    let(:column) { table.add_column :my_column, :integer, null: true, description: "Comment for this column" }
    let(:second_column) { table.add_column :my_second_column, :integer, null: true, description: "Comment for this column" }

    describe :add_index do
      describe "for simple index on one column" do
        let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name }

        it "should return the expected ruby syntax to add a index" do
          expect(generator.add_index(index)).to eq <<~RUBY
            add_index :my_table, :my_column, name: :index_name, unique: false, using: :btree, sort: :asc
          RUBY
        end
      end

      describe "for compound unique index with a custom type, order, nulls_position and a comment" do
        let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column, second_column], :index_name, unique: true, type: :gin, order: :desc, nulls_position: :first, where: "column > 0", description: "Comment for this index" }

        it "should return the expected ruby syntax to add a index" do
          expect(generator.add_index(index)).to eq <<~RUBY
            index_name_where_sql = <<~SQL
              column > 0
            SQL
            add_index :my_table, [:my_column, :my_second_column], name: :index_name, unique: true, using: :gin, sort: :desc, where: index_name_where_sql, comment: <<~COMMENT
              Comment for this index
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_index do
      describe "for simple index on one column" do
        let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name }

        it "should return the expected ruby syntax to remove a index" do
          expect(generator.remove_index(index)).to eq <<~RUBY
            remove_index :my_table, :index_name
          RUBY
        end
      end
    end
  end
end
