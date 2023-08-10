# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :ConstraintComments do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { database.add_configured_schema :my_schema }
    let(:table) { schema.add_table :my_table, description: "Comment for this table" }
    let(:column) { table.add_column :my_column, :integer, null: true, description: "Comment for this column" }

    describe :set_validation_comment do
      let(:validation) { table.add_validation :my_validation, [column.name], "my_column > 0", description: "Comment for this validation" }

      it "should return the expected ruby syntax to set a validation comment" do
        expect(generator.set_validation_comment(validation)).to eq <<~RUBY.strip
          set_validation_comment :my_table, :my_validation, <<~COMMENT
            Comment for this validation
          COMMENT
        RUBY
      end
    end

    describe :remove_validation_comment do
      let(:validation) { table.add_validation :my_validation, [column.name], "my_column > 0", description: "Comment for this validation" }

      it "should return the expected ruby syntax to remove a validation comment" do
        expect(generator.remove_validation_comment(validation)).to eq <<~RUBY.strip
          remove_validation_comment :my_table, :my_validation
        RUBY
      end
    end

    describe :set_foreign_key_constraint_comment do
      let(:foreign_table) { schema.add_table :my_foreign_table }
      let(:foreign_column) { foreign_table.add_column :my_foreign_column, :boolean }

      let(:foreign_key_constraint) { table.add_foreign_key_constraint :my_foreign_key_constraint, [column.name], :my_schema, foreign_table.name, [foreign_column.name], description: "Comment for this foreign key" }

      it "should return the expected ruby syntax to set a foreign_key_constraint comment" do
        expect(generator.set_foreign_key_constraint_comment(foreign_key_constraint)).to eq <<~RUBY.strip
          set_foreign_key_comment :my_table, :my_foreign_key_constraint, <<~COMMENT
            Comment for this foreign key
          COMMENT
        RUBY
      end
    end

    describe :remove_foreign_key_constraint_comment do
      let(:foreign_table) { schema.add_table :my_foreign_table }
      let(:foreign_column) { foreign_table.add_column :my_foreign_column, :boolean }

      let(:foreign_key_constraint) { table.add_foreign_key_constraint :my_foreign_key_constraint, [column.name], :my_schema, foreign_table.name, [foreign_column.name], description: "Comment for this foreign key" }

      it "should return the expected ruby syntax to remove a foreign_key_constraint comment" do
        expect(generator.remove_foreign_key_constraint_comment(foreign_key_constraint)).to eq <<~RUBY.strip
          remove_foreign_key_comment :my_table, :my_foreign_key_constraint
        RUBY
      end
    end

    describe :set_unique_constraint_comment do
      let(:unique_constraint) { table.add_unique_constraint :my_unique_constraint, [column.name], description: "Comment for this unique_constraint" }

      it "should return the expected ruby syntax to set a unique_constraint comment" do
        expect(generator.set_unique_constraint_comment(unique_constraint)).to eq <<~RUBY.strip
          set_unique_constraint_comment :my_table, :my_unique_constraint, <<~COMMENT
            Comment for this unique_constraint
          COMMENT
        RUBY
      end
    end

    describe :remove_unique_constraint_comment do
      let(:unique_constraint) { table.add_unique_constraint :my_unique_constraint, [column.name], description: "Comment for this unique_constraint" }

      it "should return the expected ruby syntax to remove a unique_constraint comment" do
        expect(generator.remove_unique_constraint_comment(unique_constraint)).to eq <<~RUBY.strip
          remove_unique_constraint_comment :my_table, :my_unique_constraint
        RUBY
      end
    end
  end
end
