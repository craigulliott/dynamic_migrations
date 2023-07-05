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

          describe "after tables have been added" do
            before :each do
              pg_helper.create_table :my_schema, :my_table
              pg_helper.create_table :my_schema, :my_other_table
            end

            it "creates the expected tables" do
              database.recursively_build_schemas_from_database

              schema = database.loaded_schema(:my_schema)

              expect(schema.tables).to be_a Array
              expect(schema.tables.map(&:table_name)).to eq([:my_table, :my_other_table])
            end

            describe "after two columns have been added to each table" do
              before :each do
                pg_helper.create_column :my_schema, :my_table, :my_column, :boolean
                pg_helper.create_column :my_schema, :my_table, :my_second_column, :boolean
                pg_helper.create_column :my_schema, :my_other_table, :my_column, :boolean
                pg_helper.create_column :my_schema, :my_other_table, :my_second_column, :boolean
              end

              it "creates the expected columns" do
                database.recursively_build_schemas_from_database

                table = database.loaded_schema(:my_schema).table(:my_table)
                other_table = database.loaded_schema(:my_schema).table(:my_other_table)

                expect(table.columns).to be_a Array
                expect(table.columns.map(&:column_name)).to eql [:my_column, :my_second_column]

                expect(other_table.columns).to be_a Array
                expect(other_table.columns.map(&:column_name)).to eql [:my_column, :my_second_column]
              end

              describe "after a validation has been added" do
                before :each do
                  pg_helper.create_validation :my_schema, :my_table, :my_validation, "my_column IS TRUE AND my_second_column IS TRUE"
                end

                it "creates the expected validations" do
                  database.recursively_build_schemas_from_database

                  table = database.loaded_schema(:my_schema).table(:my_table)

                  expect(table.validations).to be_a Array
                  expect(table.validations.map(&:validation_name)).to eql [:my_validation]
                end

                describe "after a unique constraint has been added" do
                  before :each do
                    pg_helper.add_unique_constraint :my_schema, :my_other_table, [:my_column, :my_second_column], :my_unique_constraint
                  end

                  it "creates the expected constraints" do
                    database.recursively_build_schemas_from_database

                    table = database.loaded_schema(:my_schema).table(:my_other_table)

                    expect(table.unique_constraints).to be_a Array
                    expect(table.unique_constraints.map(&:unique_constraint_name)).to eql [:my_unique_constraint]
                  end

                  describe "after a foreign_key has been added" do
                    before :each do
                      # note, the foreign key constraint requires a unique constraint (which was added in the previous test)
                      pg_helper.create_foreign_key :my_schema, :my_table, [:my_column, :my_second_column], :my_schema, :my_other_table, [:my_column, :my_second_column], :my_foreign_key
                    end

                    it "creates the expected foreign keys" do
                      database.recursively_build_schemas_from_database

                      table = database.loaded_schema(:my_schema).table(:my_table)

                      expect(table.foreign_key_constraints).to be_a Array
                      expect(table.foreign_key_constraints.map(&:foreign_key_constraint_name)).to eql [:my_foreign_key]
                    end

                    describe "after a primary_key has been added" do
                      before :each do
                        pg_helper.add_primary_key :my_schema, :my_table, [:my_column, :my_second_column]
                      end

                      it "creates the expected primary key" do
                        database.recursively_build_schemas_from_database

                        table = database.loaded_schema(:my_schema).table(:my_table)

                        expect(table.primary_key).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Table::PrimaryKey
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
