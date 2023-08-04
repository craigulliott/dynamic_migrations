# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :ValidationsLoader do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :fetch_validations do
      it "raises an error" do
        expect {
          database.fetch_validations
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty hash" do
          expect(database.fetch_validations).to eql({})
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "returns an empty hash" do
            expect(database.fetch_validations).to eql({})
          end

          describe "after a table has been added" do
            before :each do
              pg_helper.create_table :my_schema, :my_table
            end

            it "returns an empty hash" do
              expect(database.fetch_validations).to eql({})
            end

            describe "after two columns have been added" do
              before :each do
                pg_helper.create_column :my_schema, :my_table, :my_column, :integer
                pg_helper.create_column :my_schema, :my_table, :my_second_column, :integer
              end

              it "returns an empty hash" do
                expect(database.fetch_validations).to eql({})
              end

              describe "after a validation has been added" do
                before :each do
                  pg_helper.create_validation :my_schema, :my_table, :my_validation, "my_column > 0 AND my_second_column < 100"
                end

                it "returns the expected hash" do
                  expect(database.fetch_validations).to eql({
                    my_schema: {
                      my_table: {
                        my_validation: {
                          columns: [:my_column, :my_second_column],
                          check_clause: "my_column > 0 AND my_second_column < 100",
                          description: nil,
                          initially_deferred: false,
                          deferrable: false
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
