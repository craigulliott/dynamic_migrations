# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }

  describe :Functions do
    describe :migrations do
      describe "when the configured database has a schema" do
        let(:schema) { database.add_configured_schema :my_schema }

        before(:each) do
          schema
        end

        describe "when the configured schema has a function" do
          before(:each) do
            schema.add_function :my_function, "NEW.column = 0"
          end

          it "returns the migration to create the schema and the function" do
            expect(to_migrations.migrations).to eql({
              my_schema: [
                {
                  name: :create_my_schema_schema,
                  content: <<~RUBY.strip
                    #
                    # Create this schema
                    #
                    create_schema :my_schema
                  RUBY
                },
                {
                  name: :schema_functions,
                  content: <<~RUBY.strip
                    #
                    # Update Functions
                    #
                    my_function_definition = <<~SQL
                      NEW.column = 0;
                    SQL
                    update_function :my_function, my_function_definition, name: :my_function
                  RUBY
                }
              ]
            })
          end

          describe "when the loaded database has an equivalent schema and function" do
            before(:each) do
              loaded_schema = database.add_loaded_schema :my_schema
              loaded_schema.add_function :my_function, "NEW.column = 0"
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql({
                my_schema: []
              })
            end
          end
        end
      end
    end
  end
end
