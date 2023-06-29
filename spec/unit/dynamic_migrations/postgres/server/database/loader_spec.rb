# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :Loader do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :fetch_all do
      it "raises an error" do
        expect {
          database.fetch_all
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty hash" do
          expect(database.fetch_all).to eql({})
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "returns the expected hash" do
            expect(database.fetch_all).to eql(
              {
                my_schema: {}
              }
            )
          end

          describe "after a table has been added" do
            before :each do
              pg_helper.create_table :my_schema, :my_table
            end

            it "returns the expected hash" do
              expect(database.fetch_all).to eql(
                {
                  my_schema: {
                    my_table: {}
                  }
                }
              )
            end

            describe "after two columns have been added" do
              before :each do
                pg_helper.create_column :my_schema, :my_table, :my_column, :integer
                pg_helper.create_column :my_schema, :my_table, :my_second_column, :integer
              end

              it "returns the expected hash" do
                expect(database.fetch_all).to eql(
                  {
                    my_schema: {
                      my_table: {
                        my_column: {
                          default: nil,
                          null: true,
                          data_type: :integer,
                          numeric_precision: 32,
                          numeric_precision_radix: 2,
                          numeric_scale: 0,
                          datetime_precision: nil,
                          udt_schema: :pg_catalog,
                          udt_name: :int4,
                          updatable: true,
                          character_maximum_length: nil,
                          character_octet_length: nil

                        },
                        my_second_column: {
                          default: nil,
                          null: true,
                          data_type: :integer,
                          numeric_precision: 32,
                          numeric_precision_radix: 2,
                          numeric_scale: 0,
                          datetime_precision: nil,
                          udt_schema: :pg_catalog,
                          udt_name: :int4,
                          updatable: true,
                          character_maximum_length: nil,
                          character_octet_length: nil
                        }
                      }
                    }
                  }
                )
              end
            end
          end
        end
      end
    end

    describe :recursively_build_schema_from_database do
      it "raises an error" do
        expect {
          database.recursively_build_schema_from_database
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "creates no loaded_schema objects in the document" do
          database.recursively_build_schema_from_database

          expect(database.loaded_schemas).to eql([])
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "creates the expected schemas" do
            database.recursively_build_schema_from_database

            expect(database.loaded_schemas).to be_a Array
            expect(database.loaded_schemas.map(&:schema_name)).to eq([:my_schema])
          end

          describe "after a table has been added" do
            before :each do
              pg_helper.create_table :my_schema, :my_table
            end

            it "creates the expected tables" do
              database.recursively_build_schema_from_database

              schema = database.loaded_schema(:my_schema)

              expect(schema.tables).to be_a Array
              expect(schema.tables.map(&:table_name)).to eq([:my_table])
            end

            describe "after two columns have been added" do
              before :each do
                pg_helper.create_column :my_schema, :my_table, :my_column, :integer
                pg_helper.create_column :my_schema, :my_table, :my_second_column, :integer
              end

              it "creates the expected columns" do
                database.recursively_build_schema_from_database

                table = database.loaded_schema(:my_schema).table(:my_table)

                expect(table.columns).to be_a Array
                expect(table.columns.map(&:column_name)).to eql [:my_column, :my_second_column]
              end
            end
          end
        end
      end
    end

    describe :fetch_schema_names do
      it "raises an error" do
        expect {
          database.fetch_schema_names
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty array" do
          expect(database.fetch_schema_names).to be_empty
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "returns the expected array" do
            expect(database.fetch_schema_names).to eql ["my_schema"]
          end
        end
      end
    end

    describe :fetch_table_names do
      it "raises an error" do
        expect {
          database.fetch_table_names :my_schema
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty array" do
          expect(database.fetch_table_names(:my_schema)).to be_empty
        end

        describe "after a table has been added" do
          before :each do
            pg_helper.create_schema :my_schema
            pg_helper.create_table :my_schema, :my_table
          end

          it "returns the expected array" do
            expect(database.fetch_table_names(:my_schema)).to eql ["my_table"]
          end
        end
      end
    end

    describe :fetch_columns do
      it "raises an error" do
        expect {
          database.fetch_columns(:my_schema, :my_table)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty array" do
          expect(database.fetch_columns(:my_schema, :my_table)).to be_empty
        end

        describe "after a column has been added" do
          before :each do
            pg_helper.create_schema :my_schema
            pg_helper.create_table :my_schema, :my_table
            pg_helper.create_column :my_schema, :my_table, :my_column, :integer
          end

          it "returns the expected array" do
            expect(database.fetch_columns(:my_schema, :my_table)).to eql [{column_name: :my_column, type: :integer}]
          end
        end
      end
    end
  end
end
