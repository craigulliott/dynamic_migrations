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

          describe "after a loaded table with a description has been added" do
            let(:loaded_table) { loaded_schema.add_table :my_table, "table description" }

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
                        columns: {},
                        constraints: {}
                      }
                    },
                    exists: true
                  }
                },
                database: {
                  my_schema: {
                    tables: {
                      my_table: {
                        description: {
                          value: "table description",
                          matches: false
                        },
                        exists: true,
                        columns: {},
                        constraints: {}
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
                          description: {
                            value: nil,
                            matches: false
                          },
                          columns: {},
                          constraints: {}
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
                          description: {
                            value: "table description",
                            matches: false
                          },
                          columns: {},
                          constraints: {}
                        }
                      },
                      exists: true
                    }
                  }
                })
              end

              describe "after a loaded column has been added" do
                let(:loaded_column) { loaded_table.add_column :my_column, :boolean }

                before :each do
                  loaded_column
                end

                it "returns a hash with the expected representation of the differences" do
                  expect(database.differences).to eql(
                    {
                      configuration: {
                        my_schema: {
                          exists: true, tables: {
                            my_table: {
                              exists: true,
                              constraints: {},
                              columns: {
                                my_column: {
                                  exists: false
                                }
                              },
                              description: {
                                value: nil,
                                matches: false
                              }
                            }
                          }
                        }
                      },
                      database: {
                        my_schema: {
                          exists: true,
                          tables: {
                            my_table: {
                              exists: true,
                              constraints: {},
                              columns: {
                                my_column: {
                                  exists: true,
                                  data_type: {
                                    value: :boolean,
                                    matches: false
                                  },
                                  null: {
                                    value: nil,
                                    matches: false
                                  },
                                  default: {
                                    value: nil,
                                    matches: false
                                  },
                                  description: {
                                    value: nil,
                                    matches: false
                                  },
                                  character_maximum_length: {
                                    value: nil,
                                    matches: false
                                  },
                                  character_octet_length: {
                                    value: nil,
                                    matches: false
                                  },
                                  numeric_precision: {
                                    value: nil,
                                    matches: false
                                  },
                                  numeric_precision_radix: {
                                    value: nil,
                                    matches: false
                                  },
                                  numeric_scale: {
                                    value: nil,
                                    matches: false
                                  },
                                  datetime_precision: {
                                    value: nil,
                                    matches: false
                                  },
                                  interval_type: {
                                    value: nil,
                                    matches: false
                                  },
                                  udt_schema: {
                                    value: nil,
                                    matches: false
                                  },
                                  udt_name: {
                                    value: nil,
                                    matches: false
                                  },
                                  updatable: {
                                    value: nil,
                                    matches: false
                                  }
                                }
                              },
                              description: {
                                value: "table description",
                                matches: false
                              }
                            }
                          }
                        }
                      }
                    }
                  )
                end

                describe "after a configured column of the same name has been added" do
                  let(:configured_column) { configured_table.add_column :my_column, :integer, numeric_precision: 32, numeric_precision_radix: 2, numeric_scale: 0 }

                  before :each do
                    configured_column
                  end

                  it "returns a hash with the expected representation of the differences" do
                    expect(database.differences).to eql(
                      {
                        configuration: {
                          my_schema: {
                            exists: true,
                            tables: {
                              my_table: {
                                exists: true,
                                constraints: {},
                                columns: {
                                  my_column: {
                                    exists: true,
                                    data_type: {
                                      value: :integer,
                                      matches: false
                                    },
                                    null: {
                                      value: nil,
                                      matches: true
                                    },
                                    default: {
                                      value: nil,
                                      matches: true
                                    },
                                    description: {
                                      value: nil,
                                      matches: true
                                    },
                                    character_maximum_length: {
                                      value: nil,
                                      matches: true
                                    },
                                    character_octet_length: {
                                      value: nil,
                                      matches: true
                                    },
                                    numeric_precision: {
                                      value: 32,
                                      matches: false
                                    },
                                    numeric_precision_radix: {
                                      value: 2,
                                      matches: false
                                    },
                                    numeric_scale: {
                                      value: 0,
                                      matches: false
                                    },
                                    datetime_precision: {
                                      value: nil,
                                      matches: true
                                    },
                                    interval_type: {
                                      value: nil,
                                      matches: true
                                    },
                                    udt_schema: {
                                      value: nil,
                                      matches: true
                                    },
                                    udt_name: {
                                      value: nil,
                                      matches: true
                                    },
                                    updatable: {
                                      value: nil,
                                      matches: true
                                    }
                                  }
                                },
                                description: {
                                  value: nil,
                                  matches: false
                                }
                              }
                            }
                          }
                        },
                        database: {
                          my_schema: {
                            exists: true,
                            tables: {
                              my_table: {
                                exists: true,
                                constraints: {},
                                columns: {
                                  my_column: {
                                    exists: true,
                                    data_type: {
                                      value: :boolean,
                                      matches: false
                                    },
                                    null: {
                                      value: nil,
                                      matches: true
                                    },
                                    default: {
                                      value: nil,
                                      matches: true
                                    },
                                    description: {
                                      value: nil,
                                      matches: true
                                    },
                                    character_maximum_length: {
                                      value: nil,
                                      matches: true
                                    },
                                    character_octet_length: {
                                      value: nil,
                                      matches: true
                                    },
                                    numeric_precision: {
                                      value: nil,
                                      matches: false
                                    },
                                    numeric_precision_radix: {
                                      value: nil,
                                      matches: false
                                    },
                                    numeric_scale: {
                                      value: nil,
                                      matches: false
                                    },
                                    datetime_precision: {
                                      value: nil,
                                      matches: true
                                    },
                                    interval_type: {
                                      value: nil,
                                      matches: true
                                    },
                                    udt_schema: {
                                      value: nil,
                                      matches: true
                                    },
                                    udt_name: {
                                      value: nil,
                                      matches: true
                                    },
                                    updatable: {
                                      value: nil,
                                      matches: true
                                    }
                                  }
                                },
                                description: {
                                  value: "table description",
                                  matches: false
                                }
                              }
                            }
                          }
                        }
                      }
                    )
                  end

                  describe "after a loaded constraint has been added" do
                    let(:configured_constraint) { configured_table.add_constraint :my_constraint, [:my_column], "my_column IS TRUE" }

                    before :each do
                      configured_constraint
                    end

                    it "returns a hash with the expected representation of the differences" do
                      expect(database.differences).to eql(
                        {
                          configuration: {
                            my_schema: {
                              exists: true,
                              tables: {
                                my_table: {
                                  exists: true,
                                  constraints: {
                                    my_constraint: {
                                      exists: true,
                                      check_clause: {
                                        value: "my_column IS TRUE",
                                        matches: false
                                      }
                                    }
                                  },
                                  columns: {
                                    my_column: {
                                      exists: true,
                                      data_type: {
                                        value: :integer,
                                        matches: false
                                      },
                                      null: {
                                        value: nil,
                                        matches: true
                                      },
                                      default: {
                                        value: nil,
                                        matches: true
                                      },
                                      description: {
                                        value: nil,
                                        matches: true
                                      },
                                      character_maximum_length: {
                                        value: nil,
                                        matches: true
                                      },
                                      character_octet_length: {
                                        value: nil,
                                        matches: true
                                      },
                                      numeric_precision: {
                                        value: 32,
                                        matches: false
                                      },
                                      numeric_precision_radix: {
                                        value: 2,
                                        matches: false
                                      },
                                      numeric_scale: {
                                        value: 0,
                                        matches: false
                                      },
                                      datetime_precision: {
                                        value: nil,
                                        matches: true
                                      },
                                      interval_type: {
                                        value: nil,
                                        matches: true
                                      },
                                      udt_schema: {
                                        value: nil,
                                        matches: true
                                      },
                                      udt_name: {
                                        value: nil,
                                        matches: true
                                      },
                                      updatable: {
                                        value: nil,
                                        matches: true
                                      }
                                    }
                                  },
                                  description: {
                                    value: nil,
                                    matches: false
                                  }
                                }
                              }
                            }
                          },
                          database: {
                            my_schema: {
                              exists: true,
                              tables: {
                                my_table: {
                                  exists: true,
                                  constraints: {
                                    my_constraint: {
                                      exists: false
                                    }
                                  },
                                  columns: {
                                    my_column: {
                                      exists: true,
                                      data_type: {
                                        value: :boolean,
                                        matches: false
                                      },
                                      null: {
                                        value: nil,
                                        matches: true
                                      },
                                      default: {
                                        value: nil,
                                        matches: true
                                      },
                                      description: {
                                        value: nil,
                                        matches: true
                                      },
                                      character_maximum_length: {
                                        value: nil,
                                        matches: true
                                      },
                                      character_octet_length: {
                                        value: nil,
                                        matches: true
                                      },
                                      numeric_precision: {
                                        value: nil,
                                        matches: false
                                      },
                                      numeric_precision_radix: {
                                        value: nil,
                                        matches: false
                                      },
                                      numeric_scale: {
                                        value: nil,
                                        matches: false
                                      },
                                      datetime_precision: {
                                        value: nil,
                                        matches: true
                                      },
                                      interval_type: {
                                        value: nil,
                                        matches: true
                                      },
                                      udt_schema: {
                                        value: nil,
                                        matches: true
                                      },
                                      udt_name: {
                                        value: nil,
                                        matches: true
                                      },
                                      updatable: {
                                        value: nil,
                                        matches: true
                                      }
                                    }
                                  },
                                  description: {
                                    value: "table description",
                                    matches: false
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
        end
      end
    end
  end
end
