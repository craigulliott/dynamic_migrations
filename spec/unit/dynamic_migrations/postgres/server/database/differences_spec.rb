# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database do
  describe :Differences do
    let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

    describe :differences do
      it "returns a hash with an empty representation of the differences" do
        expect(database.differences).to eql({
          configuration: {},
          database: {}
        })
      end

      describe "after a loaded schema has been added" do
        let(:loaded_schema) { database.add_loaded_schema :my_schema }

        before :each do
          loaded_schema
        end

        it "returns a hash with the expected representation of the differences" do
          expect(database.differences).to eql({
            configuration: {
              my_schema: {
                tables: {},
                exists: false
              }
            },
            database: {
              my_schema: {
                tables: {},
                exists: true
              }
            }
          })
        end

        describe "after a configured schema of the same name has been added" do
          let(:configured_schema) { database.add_configured_schema :my_schema }

          before :each do
            configured_schema
          end

          it "returns a hash with the expected representation of the differences" do
            expect(database.differences).to eql({
              configuration: {
                my_schema: {
                  tables: {},
                  exists: true
                }
              },
              database: {
                my_schema: {
                  tables: {},
                  exists: true
                }
              }
            })
          end

          describe "after a loaded table has been added" do
            let(:loaded_table) { loaded_schema.add_table :my_table }

            before :each do
              loaded_table
            end

            it "returns a hash with the expected representation of the differences" do
              expect(database.differences).to eql({
                configuration: {
                  my_schema: {
                    tables: {
                      my_table: {
                        exists: false,
                        columns: {}
                      }
                    },
                    exists: true
                  }
                },
                database: {
                  my_schema: {
                    tables: {
                      my_table: {
                        exists: true,
                        columns: {}
                      }
                    },
                    exists: true
                  }
                }
              })
            end

            describe "after a configured table of the same name has been added" do
              let(:configured_table) { configured_schema.add_table :my_table }

              before :each do
                configured_table
              end

              it "returns a hash with the expected representation of the differences" do
                expect(database.differences).to eql({
                  configuration: {
                    my_schema: {
                      tables: {
                        my_table: {
                          exists: true,
                          columns: {}
                        }
                      },
                      exists: true
                    }
                  },
                  database: {
                    my_schema: {
                      tables: {
                        my_table: {
                          exists: true,
                          columns: {}
                        }
                      },
                      exists: true
                    }
                  }
                })
              end

              describe "after a loaded column has been added" do
                let(:loaded_column) { loaded_table.add_column :my_column, :integer }

                before :each do
                  loaded_column
                end

                it "returns a hash with the expected representation of the differences" do
                  expect(database.differences).to eql({
                    configuration: {
                      my_schema: {
                        tables: {
                          my_table: {
                            exists: true,
                            columns: {
                              my_column: {
                                exists: false
                              }
                            }
                          }
                        },
                        exists: true
                      }
                    },
                    database: {
                      my_schema: {
                        tables: {
                          my_table: {
                            exists: true,
                            columns: {
                              my_column: {
                                exists: true
                              }
                            }
                          }
                        },
                        exists: true
                      }
                    }
                  })
                end

                describe "after a configured column of the same name has been added" do
                  let(:configured_column) { configured_table.add_column :my_column, :integer }

                  before :each do
                    configured_column
                  end

                  it "returns a hash with the expected representation of the differences" do
                    expect(database.differences).to eql({
                      configuration: {
                        my_schema: {
                          tables: {
                            my_table: {
                              exists: true,
                              columns: {
                                my_column: {
                                  exists: true
                                }
                              }
                            }
                          },
                          exists: true
                        }
                      },
                      database: {
                        my_schema: {
                          tables: {
                            my_table: {
                              exists: true,
                              columns: {
                                my_column: {
                                  exists: true
                                }
                              }
                            }
                          },
                          exists: true
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
