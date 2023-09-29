# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :StructureLoader do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :fetch_structure do
      it "raises an error" do
        expect {
          database.fetch_structure
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns only the empty public schema" do
          expect(database.fetch_structure).to eql({
            public: {
              tables: {}
            }
          })
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "returns the expected hash" do
            expect(database.fetch_structure).to eql(
              {
                my_schema: {
                  tables: {}
                },
                public: {
                  tables: {}
                }
              }
            )
          end

          describe "after a table has been added" do
            before :each do
              pg_helper.create_table :my_schema, :my_table
            end

            it "returns the expected hash" do
              expect(database.fetch_structure).to eql(
                {
                  public: {
                    tables: {}
                  },

                  my_schema: {
                    tables: {
                      my_table: {
                        description: nil,
                        columns: {}
                      }
                    }
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
                expect(database.fetch_structure).to eql(
                  {
                    public: {
                      tables: {}
                    },
                    my_schema: {
                      tables: {
                        my_table: {
                          description: nil,
                          columns: {
                            my_column: {
                              default: nil,
                              null: true,
                              description: nil,
                              data_type: :integer,
                              interval_type: nil,
                              is_enum: false,
                              is_array: false
                            },
                            my_second_column: {
                              default: nil,
                              null: true,
                              description: nil,
                              data_type: :integer,
                              interval_type: nil,
                              is_enum: false,
                              is_array: false
                            }
                          }
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
  end
end
