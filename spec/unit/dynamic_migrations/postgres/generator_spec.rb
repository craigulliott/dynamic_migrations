# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }

  describe :migrations do
    describe "for a table with uuid primary key, timestamps, and two other colums" do
      before(:each) do
        table.add_column :id, :uuid, null: false, default: "uuid_generate_v4()"
        table.add_primary_key :my_table_primary_key_name, [:id]
        table.add_column :foo, :varchar, null: false, default: "foo", description: "Comment for this column"
        table.add_column :bar, :varchar, null: false, default: "foo", description: "Comment for this column"
        table.add_column :created_at, :timestamp
        table.add_column :updated_at, :timestamp

        generator.create_table(table)
      end

      it "should return the expected ruby syntax to create a table" do
        expect(generator.migrations).to eql({
          my_schema: [
            {
              name: :create_my_table,
              content: <<~RUBY.strip
                #
                # Create Tables
                #
                table_comment = <<~COMMENT
                  Comment for this table
                COMMENT
                create_table :my_table, id: :uuid, comment: table_comment do |t|
                  t.varchar :bar, null: false, default: "foo", comment: <<~COMMENT
                    Comment for this column
                  COMMENT
                  t.varchar :foo, null: false, default: "foo", comment: <<~COMMENT
                    Comment for this column
                  COMMENT
                  t.timestamps :created_at, :updated_at
                end
              RUBY
            }
          ]
        })
      end
    end
  end

  describe :supported_migration_method_names do
    it "should return an array of method names" do
      expect(generator.send(:supported_migration_method_names)).to be_an(Array)
    end

    it "each method name should ony exist once (this ensures we do not duplicate the content in multiple sections)" do
      expect(generator.send(:supported_migration_method_names)).to eql(generator.send(:supported_migration_method_names).uniq)
    end
  end
end