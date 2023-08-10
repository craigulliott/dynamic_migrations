# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Validation do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }
    let(:column) { table.add_column :my_column, :integer, null: true, description: "Comment for this column" }

    describe :add_validation do
      describe "for simple validation on one column" do
        let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column > 0" }

        it "should return the expected ruby syntax to add a validation" do
          expect(generator.add_validation(validation)).to eq <<~RUBY.strip
            add_validation :my_table, name: :validation_name, deferrable: false, initially_deferred: false do
              <<~SQL
                my_column > 0;
              SQL
            end
          RUBY
        end
      end

      describe "for simple validation on one column which has a description" do
        let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column > 0", description: "My validation" }

        it "should return the expected ruby syntax to add a validation" do
          expect(generator.add_validation(validation)).to eq <<~RUBY.strip
            validation_name_comment = <<~COMMENT
              My validation
            COMMENT
            add_validation :my_table, name: :validation_name, deferrable: false, initially_deferred: false, comment: validation_name_comment do
              <<~SQL
                my_column > 0;
              SQL
            end
          RUBY
        end
      end
    end

    describe :remove_validation do
      describe "for simple validation on one column" do
        let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column > 0" }

        it "should return the expected ruby syntax to remove a validation" do
          expect(generator.remove_validation(validation)).to eq <<~RUBY.strip
            remove_validation :my_table, :validation_name
          RUBY
        end
      end
    end
  end
end
