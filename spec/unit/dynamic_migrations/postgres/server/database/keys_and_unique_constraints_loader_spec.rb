# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :KeysAndUniqueConstraintsLoader do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :fetch_keys_and_unique_constraints do
      it "raises an error" do
        expect {
          database.fetch_keys_and_unique_constraints
        }.to raise_error DynamicMigrations::Postgres::Server::Database::NotConnectedError
      end

      describe "after a connection has been established" do
        before :each do
          database.connect
        end

        it "returns an empty hash" do
          expect(database.fetch_keys_and_unique_constraints).to eql({})
        end

        describe "after a schema has been added" do
          before :each do
            pg_helper.create_schema :my_schema
          end

          it "returns an empty hash" do
            expect(database.fetch_keys_and_unique_constraints).to eql({})
          end

          describe "after tables have been added" do
            before :each do
              pg_helper.create_table :my_schema, :my_table
              pg_helper.create_table :my_schema, :my_other_table
            end

            it "returns an empty hash" do
              expect(database.fetch_keys_and_unique_constraints).to eql({})
            end

            describe "after two columns have been added to each table" do
              before :each do
                pg_helper.create_column :my_schema, :my_table, :my_column, :integer
                pg_helper.create_column :my_schema, :my_table, :my_second_column, :integer
                pg_helper.create_column :my_schema, :my_other_table, :my_column, :integer
                pg_helper.create_column :my_schema, :my_other_table, :my_second_column, :integer
              end

              it "returns an empty hash" do
                expect(database.fetch_keys_and_unique_constraints).to eql({})
              end

              describe "after a unique constraint has been added" do
                before :each do
                  pg_helper.create_unique_constraint :my_schema, :my_other_table, [:my_column, :my_second_column], :my_unique_constraint
                end

                it "returns the expected hash" do
                  expect(database.fetch_keys_and_unique_constraints).to eql({
                    my_schema: {
                      my_other_table: {
                        UNIQUE: {
                          my_unique_constraint: {
                            column_names: [
                              :my_column,
                              :my_second_column
                            ],
                            foreign_schema_name: nil,
                            foreign_table_name: nil,
                            foreign_column_names: nil,
                            deferrable: false,
                            initially_deferred: false,
                            index_type: :btree
                          }
                        }
                      }
                    }
                  })
                end

                describe "after a foreign_key has been added" do
                  before :each do
                    # note, the foreign key constraint requires a unique constraint (which was added in the previous test)
                    pg_helper.create_foreign_key :my_schema, :my_table, [:my_column, :my_second_column], :my_schema, :my_other_table, [:my_column, :my_second_column], :my_foreign_key
                  end

                  it "returns the expected hash" do
                    expect(database.fetch_keys_and_unique_constraints).to eql({
                      my_schema: {
                        my_other_table: {
                          UNIQUE: {
                            my_unique_constraint: {
                              column_names: [
                                :my_column,
                                :my_second_column
                              ],
                              foreign_schema_name: nil,
                              foreign_table_name: nil,
                              foreign_column_names: nil,
                              deferrable: false,
                              initially_deferred: false,
                              index_type: :btree
                            }
                          }
                        },
                        my_table: {
                          FOREIGN_KEY: {
                            my_foreign_key: {
                              column_names: [
                                :my_column,
                                :my_second_column
                              ],
                              foreign_schema_name: :my_schema,
                              foreign_table_name: :my_other_table,
                              foreign_column_names: [
                                :my_column,
                                :my_second_column
                              ],
                              deferrable: false,
                              initially_deferred: false,
                              index_type: nil
                            }
                          }
                        }
                      }
                    })
                  end

                  describe "after a primary_key has been added" do
                    before :each do
                      # note, the foreign key constraint requires a unique constraint (which was added in the previous test)
                      pg_helper.create_primary_key :my_schema, :my_table, [:my_column, :my_second_column], :my_primary_key
                    end

                    it "returns the expected hash" do
                      expect(database.fetch_keys_and_unique_constraints).to eql({
                        my_schema: {
                          my_other_table: {
                            UNIQUE: {
                              my_unique_constraint: {
                                column_names: [
                                  :my_column,
                                  :my_second_column
                                ],
                                foreign_schema_name: nil,
                                foreign_table_name: nil,
                                foreign_column_names: nil,
                                deferrable: false,
                                initially_deferred: false,
                                index_type: :btree
                              }
                            }
                          },
                          my_table: {
                            FOREIGN_KEY: {
                              my_foreign_key: {
                                column_names: [
                                  :my_column,
                                  :my_second_column
                                ],
                                foreign_schema_name: :my_schema,
                                foreign_table_name: :my_other_table,
                                foreign_column_names: [:my_column, :my_second_column],
                                deferrable: false,
                                initially_deferred: false,
                                index_type: nil
                              }
                            },
                            PRIMARY_KEY: {
                              my_primary_key: {
                                column_names: [
                                  :my_column,
                                  :my_second_column
                                ],
                                foreign_schema_name: nil,
                                foreign_table_name: nil,
                                foreign_column_names: nil,
                                deferrable: false,
                                initially_deferred: false,
                                index_type: :btree
                              }
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
  end
end
