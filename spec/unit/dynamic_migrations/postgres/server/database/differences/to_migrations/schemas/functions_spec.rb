# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }

  describe :Functions do
    describe :migrations do
      describe "when the loaded and configured database have the same schema" do
        let(:configured_schema) { database.add_configured_schema :my_schema }
        let(:loaded_schema) { database.add_loaded_schema :my_schema }

        before(:each) do
          configured_schema
          loaded_schema
        end

        describe "when the configured schema has a function" do
          before(:each) do
            configured_schema.add_function :my_function, "NEW.column = 0"
          end

          it "returns the migration to create the function" do
            expect(to_migrations.migrations).to eql({
              my_schema: [
                {
                  name: :create_function_my_function,
                  content: <<~RUBY.strip
                    #
                    # Functions
                    #
                    create_function :my_function do
                      <<~SQL
                        NEW.column = 0;
                      SQL
                    end
                  RUBY
                }
              ]
            })
          end

          describe "when the loaded database has the same function but a different function definition" do
            before(:each) do
              loaded_schema.add_function :my_function, "NEW.different_column = 0"
            end

            it "returns the migration to update the function" do
              expect(to_migrations.migrations).to eql({
                my_schema: [{
                  name: :schema_functions,
                  content: <<~RUBY.strip
                    #
                    # Update Functions
                    #
                    update_function :my_function do
                      <<~SQL
                        NEW.column = 0;
                      SQL
                    end
                  RUBY
                }]
              })
            end
          end

          describe "when the loaded database has an equivalent function" do
            before(:each) do
              loaded_schema.add_function :my_function, "NEW.column = 0"
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql({})
            end
          end
        end

        describe "when the configured schema has a function with a description" do
          before(:each) do
            configured_schema.add_function :my_function, "NEW.column = 0", description: "Description of my function"
          end

          it "returns the migration to create the function and description" do
            expect(to_migrations.migrations).to eql({
              my_schema: [
                {
                  name: :create_function_my_function,
                  content: <<~RUBY.strip
                    #
                    # Functions
                    #
                    my_function_comment = <<~COMMENT
                      Description of my function
                    COMMENT
                    create_function :my_function, comment: my_function_comment do
                      <<~SQL
                        NEW.column = 0;
                      SQL
                    end
                  RUBY
                }
              ]
            })
          end

          describe "when the loaded schema has the same function but a different description" do
            before(:each) do
              loaded_schema.add_function :my_function, "NEW.column = 0", description: "Different description of my function"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql({
                my_schema: [{
                  name: :schema_functions,
                  content: <<~RUBY.strip
                    #
                    # Update Functions
                    #
                    set_function_comment :my_function, <<~COMMENT
                      Description of my function
                    COMMENT
                  RUBY
                }]
              })
            end
          end

          describe "when the loaded schema has the same function but a different description and definition" do
            before(:each) do
              loaded_schema.add_function :my_function, "NEW.different_column = 0", description: "Different description of my function"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql({
                my_schema: [{
                  name: :schema_functions,
                  content: <<~RUBY.strip
                    #
                    # Update Functions
                    #
                    update_function :my_function do
                      <<~SQL
                        NEW.column = 0;
                      SQL
                    end

                    set_function_comment :my_function, <<~COMMENT
                      Description of my function
                    COMMENT
                  RUBY
                }]
              })
            end
          end

          describe "when the loaded schema has an equivalent function and description" do
            before(:each) do
              loaded_schema.add_function :my_function, "NEW.column = 0", description: "Description of my function"
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql({})
            end
          end
        end
      end
    end
  end
end
