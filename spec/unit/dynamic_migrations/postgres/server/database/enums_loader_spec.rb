# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :EnumsLoader do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :fetch_enums do
      it "raises an error" do
        expect {
          database.fetch_enums
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty hash" do
          expect(database.fetch_enums).to eql({})
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "returns an empty hash" do
            expect(database.fetch_enums).to eql({})
          end

          describe "after enums have been added" do
            before :each do
              pg_helper.create_enum :my_schema, :my_enum, [:foo, :bar]
              pg_helper.create_enum :my_schema, :my_other_enum, [:foo, :bar]
            end

            it "returns the expected hash" do
              expect(database.fetch_enums).to eql({
                my_schema: {
                  my_enum: {
                    values: [:foo, :bar],
                    description: nil
                  },
                  my_other_enum: {
                    values: [:foo, :bar],
                    description: nil
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
