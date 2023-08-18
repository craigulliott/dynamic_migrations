# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :TriggersAndFunctionsLoader do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :fetch_triggers_and_functions do
      it "raises an error" do
        expect {
          database.fetch_triggers_and_functions
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty hash" do
          expect(database.fetch_triggers_and_functions).to eql({})
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "returns an empty hash" do
            expect(database.fetch_triggers_and_functions).to eql({})
          end

          describe "after tables have been added" do
            before :each do
              pg_helper.create_table :my_schema, :my_table
              pg_helper.create_table :my_schema, :my_other_table
            end

            it "returns an empty hash" do
              expect(database.fetch_triggers_and_functions).to eql({})
            end

            describe "after two columns have been added to each table" do
              before :each do
                pg_helper.create_column :my_schema, :my_table, :my_column, :integer
                pg_helper.create_column :my_schema, :my_table, :my_second_column, :integer
                pg_helper.create_column :my_schema, :my_other_table, :my_column, :integer
                pg_helper.create_column :my_schema, :my_other_table, :my_second_column, :integer
              end

              it "returns an empty hash" do
                expect(database.fetch_triggers_and_functions).to eql({})
              end

              describe "after a trigger and function have been added" do
                before :each do
                  pg_helper.create_function :my_schema, :my_function, <<~SQL
                    BEGIN
                      NEW.my_column = 0;
                      RETURN NEW;
                    END;
                  SQL
                  pg_helper.create_trigger :my_schema, :my_table, :my_trigger, action_timing: :before, event_manipulation: :insert, action_orientation: :row, function_schema: :my_schema, function_name: :my_function, action_condition: "NEW.my_column != 0"
                end

                it "returns the expected hash" do
                  expect(database.fetch_triggers_and_functions).to eql({
                    my_schema: {
                      my_table: {
                        my_trigger: {
                          trigger_schema: :my_schema,
                          event_manipulation: :insert,
                          action_order: 1,
                          action_condition: "((new.my_column <> 0))",
                          function_schema: :my_schema,
                          function_name: :my_function,
                          function_definition: "BEGIN\n  NEW.my_column = 0;\n  RETURN NEW;\nEND;",
                          parameters: nil,
                          action_orientation: :row,
                          action_timing: :before,
                          action_reference_old_table: nil,
                          action_reference_new_table: nil,
                          description: nil,
                          function_description: nil
                        }
                      }
                    }
                  })
                end
              end
            end
          end
        end
      end
    end
  end
end
