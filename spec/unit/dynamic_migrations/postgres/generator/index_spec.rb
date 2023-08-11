# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

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
        let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :my_index }

        it "should return the expected ruby syntax to add a index" do
          expect(generator.add_index(index).to_s).to eq <<~RUBY.strip
            add_index :my_table, :my_column, name: :my_index, unique: false, using: :btree, sort: :asc
          RUBY
        end
      end

      describe "for compound unique index with a custom type, order, nulls_position and a comment" do
        let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column, second_column], :my_index, unique: true, type: :gin, order: :desc, nulls_position: :first, where: "column > 0", description: "Comment for this index" }

        it "should return the expected ruby syntax to add a index" do
          expect(generator.add_index(index).to_s).to eq <<~RUBY.strip
            my_index_where_sql = <<~SQL
              column > 0
            SQL
            add_index :my_table, [:my_column, :my_second_column], name: :my_index, unique: true, using: :gin, sort: :desc, where: my_index_where_sql, comment: <<~COMMENT
              Comment for this index
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_index do
      describe "for simple index on one column" do
        let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :my_index }

        it "should return the expected ruby syntax to remove a index" do
          expect(generator.remove_index(index).to_s).to eq <<~RUBY.strip
            remove_index :my_table, :my_index
          RUBY
        end
      end
    end

    describe :recreate_index do
      describe "for indexes with different where values" do
        let(:original_index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :my_index }
        let(:updated_index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :my_index, where: "column > 0" }

        it "should return the expected ruby syntax to recreate a index" do
          remove = <<~RUBY.strip
            # Removing original index because it has changed (it is recreated below)
            # Changes:
            #   where changed from `` to `column > 0`
            remove_index :my_table, :my_index
          RUBY
          re_add = <<~RUBY.strip
            # Recreating this index
            my_index_where_sql = <<~SQL
              column > 0
            SQL
            add_index :my_table, :my_column, name: :my_index, unique: false, using: :btree, sort: :asc, where: my_index_where_sql
          RUBY
          expect(generator.recreate_index(original_index, updated_index).map(&:to_s)).to eq [remove, re_add]
        end
      end
    end

    describe :set_index_comment do
      let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :my_index, description: "Comment for this index" }

      it "should return the expected ruby syntax to set a index comment" do
        expect(generator.set_index_comment(index).to_s).to eq <<~RUBY.strip
          set_index_comment :my_table, :my_index, <<~COMMENT
            Comment for this index
          COMMENT
        RUBY
      end
    end

    describe :remove_index_comment do
      let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :my_index }

      it "should return the expected ruby syntax to remove a index comment" do
        expect(generator.remove_index_comment(index).to_s).to eq <<~RUBY.strip
          remove_index_comment :my_table, :my_index
        RUBY
      end
    end
  end
end
