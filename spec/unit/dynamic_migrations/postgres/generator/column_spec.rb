# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Column do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }

    describe :add_column do
      describe "for a nullable uuid with no default" do
        let(:column) { table.add_column :my_column, :char, null: true, description: "Comment for this column" }

        it "should return the expected ruby syntax to add a column" do
          expect(generator.add_column(column)).to eq <<~RUBY.strip
            add_column :my_table, :my_column, :char, null: true, comment: <<~COMMENT
              Comment for this column
            COMMENT
          RUBY
        end
      end

      describe "for a non nullable char with a default" do
        let(:column) { table.add_column :my_column, :char, null: false, default: "default_str", description: "Comment for this column" }

        it "should return the expected ruby syntax to add a column" do
          expect(generator.add_column(column)).to eq <<~RUBY.strip
            add_column :my_table, :my_column, :char, null: false, default: "default_str", comment: <<~COMMENT
              Comment for this column
            COMMENT
          RUBY
        end
      end

      describe "for an array column" do
        let(:column) { table.add_column :my_column, :"char[]", null: true, description: "Comment for this column" }

        it "should return the expected ruby syntax to add a column" do
          expect(generator.add_column(column)).to eq <<~RUBY.strip
            add_column :my_table, :my_column, :"char[]", null: true, array: true, comment: <<~COMMENT
              Comment for this column
            COMMENT
          RUBY
        end
      end
    end

    describe :change_column do
      describe "for a nullable uuid with no default" do
        let(:column) { table.add_column :my_column, :char, null: true, description: "Comment for this column" }

        it "should return the expected ruby syntax to change a column" do
          expect(generator.change_column(column)).to eq <<~RUBY.strip
            change_column :my_table, :my_column, :char, null: true
          RUBY
        end
      end

      describe "for a non nullable char with a default" do
        let(:column) { table.add_column :my_column, :char, null: false, default: "default_str", description: "Comment for this column" }

        it "should return the expected ruby syntax to change a column" do
          expect(generator.change_column(column)).to eq <<~RUBY.strip
            change_column :my_table, :my_column, :char, null: false, default: "default_str"
          RUBY
        end
      end
    end

    describe :remove_column do
      let(:column) { table.add_column :my_column, :char, null: false, default: "default_str", description: "Comment for this column" }

      it "should return the expected ruby syntax to remove a column" do
        expect(generator.remove_column(column)).to eq <<~RUBY.strip
          remove_column :my_table, :my_column
        RUBY
      end
    end

    describe :set_column_comment do
      let(:column) { table.add_column :my_column, :char, null: false, default: "default_str", description: "Comment for this column" }

      it "should return the expected ruby syntax to set a column comment" do
        expect(generator.set_column_comment(column)).to eq <<~RUBY.strip
          set_column_comment :my_table, :my_column, <<~COMMENT
            Comment for this column
          COMMENT
        RUBY
      end
    end

    describe :remove_column_comment do
      let(:column) { table.add_column :my_column, :char, null: false, default: "default_str", description: "Comment for this column" }

      it "should return the expected ruby syntax to remove a column comment" do
        expect(generator.remove_column_comment(column)).to eq <<~RUBY.strip
          remove_column_comment :my_table, :my_column
        RUBY
      end
    end
  end
end
