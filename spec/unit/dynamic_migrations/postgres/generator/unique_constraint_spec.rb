# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :UniqueConstraint do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }
    let(:column) { table.add_column :my_column, :integer, null: true, description: "Comment for this column" }
    let(:second_column) { table.add_column :my_second_column, :integer, null: true, description: "Comment for this column" }

    describe :add_unique_constraint do
      describe "for simple unique_constraint on one column" do
        let(:unique_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name }

        it "should return the expected ruby syntax to add a unique_constraint" do
          expect(generator.add_unique_constraint(unique_constraint).to_s).to eq <<~RUBY.strip
            add_unique_constraint :my_table, :my_column, name: :unique_constraint_name, deferrable: false, initially_deferred: false
          RUBY
        end
      end

      describe "for compound unique unique_constraint with a custom order, nulls_position and a comment" do
        let(:unique_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column, second_column], :unique_constraint_name, deferrable: true, initially_deferred: true, description: "Comment for this unique_constraint" }

        it "should return the expected ruby syntax to add a unique_constraint" do
          expect(generator.add_unique_constraint(unique_constraint).to_s).to eq <<~RUBY.strip
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
          expect(generator.remove_unique_constraint(unique_constraint).to_s).to eq <<~RUBY.strip
            remove_unique_constraint :my_table, :unique_constraint_name
          RUBY
        end
      end
    end

    describe :recreate_unique_constraint do
      describe "for unique_constraints with different deferrable values" do
        let(:original_unique_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name }
        let(:updated_unique_constraint) { DynamicMigrations::Postgres::Server::Database::Schema::Table::UniqueConstraint.new :configuration, table, [column], :unique_constraint_name, deferrable: true, initially_deferred: true }

        it "should return the expected ruby syntax to recreate a unique_constraint" do
          remove = <<~RUBY.strip
            # Removing original unique constraint because it has changed (it is recreated below)
            # Changes:
            #   deferrable changed from `false` to `true`
            #   initially_deferred changed from `false` to `true`
            remove_unique_constraint :my_table, :unique_constraint_name
          RUBY
          re_add = <<~RUBY.strip
            # Recreating this unique constraint
            add_unique_constraint :my_table, :my_column, name: :unique_constraint_name, deferrable: true, initially_deferred: true
          RUBY
          expect(generator.recreate_unique_constraint(original_unique_constraint, updated_unique_constraint).map(&:to_s)).to eq [remove, re_add]
        end
      end
    end

    describe :set_unique_constraint_comment do
      let(:unique_constraint) { table.add_unique_constraint :my_unique_constraint, [column.name], description: "Comment for this unique_constraint" }

      it "should return the expected ruby syntax to set a unique_constraint comment" do
        expect(generator.set_unique_constraint_comment(unique_constraint).to_s).to eq <<~RUBY.strip
          set_unique_constraint_comment :my_table, :my_unique_constraint, <<~COMMENT
            Comment for this unique_constraint
          COMMENT
        RUBY
      end
    end

    describe :remove_unique_constraint_comment do
      let(:unique_constraint) { table.add_unique_constraint :my_unique_constraint, [column.name], description: "Comment for this unique_constraint" }

      it "should return the expected ruby syntax to remove a unique_constraint comment" do
        expect(generator.remove_unique_constraint_comment(unique_constraint).to_s).to eq <<~RUBY.strip
          remove_unique_constraint_comment :my_table, :my_unique_constraint
        RUBY
      end
    end
  end
end
