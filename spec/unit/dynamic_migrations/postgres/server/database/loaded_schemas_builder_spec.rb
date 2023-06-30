# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :LoadedSchemasBuilder do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :recursively_build_schemas_from_database do
      it "raises an error" do
        expect {
          database.recursively_build_schemas_from_database
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "creates only the default public schema" do
          database.recursively_build_schemas_from_database

          expect(database.loaded_schemas).to be_a Array
          expect(database.loaded_schemas.map(&:schema_name)).to eq([:public])
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "creates the expected schemas" do
            database.recursively_build_schemas_from_database

            expect(database.loaded_schemas).to be_a Array
            expect(database.loaded_schemas.map(&:schema_name)).to eq([:my_schema, :public])
          end

          describe "after a table has been added" do
            before :each do
              pg_helper.create_table :my_schema, :my_table
            end

            it "creates the expected tables" do
              database.recursively_build_schemas_from_database

              schema = database.loaded_schema(:my_schema)

              expect(schema.tables).to be_a Array
              expect(schema.tables.map(&:table_name)).to eq([:my_table])
            end

            describe "after two columns have been added" do
              before :each do
                pg_helper.create_column :my_schema, :my_table, :my_column, :boolean
                pg_helper.create_column :my_schema, :my_table, :my_second_column, :boolean
              end

              it "creates the expected columns" do
                database.recursively_build_schemas_from_database

                table = database.loaded_schema(:my_schema).table(:my_table)

                expect(table.columns).to be_a Array
                expect(table.columns.map(&:column_name)).to eql [:my_column, :my_second_column]
              end

              describe "after a constraint has been added" do
                before :each do
                  pg_helper.create_constraint :my_schema, :my_table, :my_constraint, "my_column IS TRUE AND my_second_column IS TRUE"
                end

                it "creates the expected columns" do
                  database.recursively_build_schemas_from_database

                  table = database.loaded_schema(:my_schema).table(:my_table)

                  expect(table.constraints).to be_a Array
                  expect(table.constraints.map(&:constraint_name)).to eql [:my_constraint]
                end
              end
            end
          end
        end
      end
    end
  end
end
