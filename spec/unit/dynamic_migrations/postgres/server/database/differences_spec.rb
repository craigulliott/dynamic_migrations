# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:pg_helper) { RSpec.configuration.primary_postgres_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }

  describe :initialize do
    it "instantiates a new differences without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Differences.new database
      }.to_not raise_error
    end

    it "raises an error if providing an invalid database" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Differences.new "not a database object"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Differences::ExpectedDatabaseError
    end
  end

  describe :to_h do
    it "returns the expected differences" do
      expect(differences.to_h).to eql({
        configuration: {},
        database: {}
      })
    end

    describe "when the configured database has a schema" do
      let(:configured_schema) { database.add_configured_schema :my_schema }

      before(:each) do
        configured_schema
      end

      it "returns the expected differences" do
        expect(differences.to_h).to eql({
          configuration: {
            my_schema: {
              exists: true,
              tables: {}
            }
          },
          database: {
            my_schema: {
              exists: false
            }
          }
        })
      end

      describe "when the loaded database has an equivalent schema" do
        let(:loaded_schema) { database.add_loaded_schema :my_schema }

        before(:each) do
          loaded_schema
        end

        it "returns the expected differences" do
          expect(differences.to_h).to eql({
            configuration: {
              my_schema: {
                exists: true,
                tables: {}
              }
            },
            database: {
              my_schema: {
                exists: true,
                tables: {}
              }
            }
          })
        end

        describe "when the configured schema has a table" do
          let(:configured_table) { configured_schema.add_table :my_table }

          before(:each) do
            configured_table
          end

          it "returns the expected differences" do
            expect(differences.to_h).to eql({
              configuration: {
                my_schema: {
                  exists: true,
                  tables: {
                    my_table: {
                      exists: true,
                      description: {
                        value: nil,
                        matches: false
                      },
                      primary_key: {
                        exists: false
                      },
                      columns: {},
                      validations: {},
                      foreign_key_constraints: {},
                      unique_constraints: {}
                    }
                  }
                }
              },
              database: {
                my_schema: {
                  exists: true,
                  tables: {
                    my_table: {
                      exists: false
                    }
                  }
                }
              }
            })
          end

          describe "when the loaded database has an equivalent table" do
            let(:loaded_table) { loaded_schema.add_table :my_table }

            before(:each) do
              loaded_table
            end

            it "returns the expected differences" do
              expect(differences.to_h).to eql({
                configuration: {
                  my_schema: {
                    exists: true,
                    tables: {
                      my_table: {
                        exists: true,
                        description: {
                          value: nil,
                          matches: true
                        },
                        primary_key: {
                          exists: false
                        },
                        columns: {},
                        validations: {},
                        foreign_key_constraints: {},
                        unique_constraints: {}

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
                        description: {
                          value: nil,
                          matches: true
                        },
                        primary_key: {
                          exists: false
                        },
                        columns: {},
                        validations: {},
                        foreign_key_constraints: {},
                        unique_constraints: {}
                      }
                    }
                  }
                }
              })
            end

            describe "when the configured table has a column" do
              before(:each) do
                configured_table.add_column :my_column, :integer, numeric_precision: 32, numeric_precision_radix: 2, numeric_scale: 0
              end

              it "returns the expected differences" do
                expect(differences.to_h).to eql({
                  configuration: {
                    my_schema: {
                      exists: true,
                      tables: {
                        my_table: {
                          exists: true,
                          description: {
                            value: nil,
                            matches: true
                          },
                          primary_key: {
                            exists: false
                          },
                          columns: {
                            my_column: {
                              exists: true,
                              data_type: {
                                value: :integer,
                                matches: false
                              },
                              null: {
                                value: true,
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
                                value: true,
                                matches: false
                              }
                            }
                          },
                          validations: {},
                          foreign_key_constraints: {},
                          unique_constraints: {}
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
                          description: {
                            value: nil,
                            matches: true
                          },
                          primary_key: {
                            exists: false
                          },
                          columns: {
                            my_column: {
                              exists: false
                            }
                          },
                          validations: {},
                          foreign_key_constraints: {},
                          unique_constraints: {}
                        }
                      }
                    }
                  }
                })
              end

              describe "when the loaded database has an equivalent column" do
                before(:each) do
                  loaded_table.add_column :my_column, :integer, numeric_precision: 32, numeric_precision_radix: 2, numeric_scale: 0
                end

                it "returns the expected differences" do
                  expect(differences.to_h).to eql({
                    configuration: {
                      my_schema: {
                        exists: true,
                        tables: {
                          my_table: {
                            exists: true,
                            description: {
                              value: nil,
                              matches: true
                            },
                            primary_key: {
                              exists: false
                            },
                            columns: {
                              my_column: {
                                exists: true,
                                data_type: {
                                  value: :integer,
                                  matches: true
                                },
                                null: {
                                  value: true,
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
                                  matches: true
                                },
                                numeric_precision_radix: {
                                  value: 2,
                                  matches: true
                                },
                                numeric_scale: {
                                  value: 0,
                                  matches: true
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
                                  value: true,
                                  matches: true
                                }
                              }
                            },
                            validations: {},
                            foreign_key_constraints: {},
                            unique_constraints: {}
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
                            description: {
                              value: nil,
                              matches: true
                            },
                            primary_key: {
                              exists: false
                            },
                            columns: {
                              my_column: {
                                exists: true,
                                data_type: {
                                  value: :integer,
                                  matches: true
                                },
                                null: {
                                  value: true,
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
                                  matches: true
                                },
                                numeric_precision_radix: {
                                  value: 2,
                                  matches: true
                                },
                                numeric_scale: {
                                  value: 0,
                                  matches: true
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
                                  value: true,
                                  matches: true
                                }
                              }
                            },
                            validations: {},
                            foreign_key_constraints: {},
                            unique_constraints: {}
                          }
                        }
                      }
                    }
                  })
                end

                describe "when the configured table has a primary_key" do
                  before(:each) do
                    configured_table.add_primary_key :my_primary_key, [:my_column]
                  end

                  it "returns the expected differences" do
                    expect(differences.to_h).to eql({
                      configuration: {
                        my_schema: {
                          exists: true,
                          tables: {
                            my_table: {
                              exists: true,
                              description: {
                                value: nil,
                                matches: true
                              },
                              primary_key: {
                                exists: true,
                                primary_key_name: {
                                  value: :my_primary_key,
                                  matches: false
                                },
                                index_type: {
                                  value: :btree,
                                  matches: false
                                }
                              },
                              columns: {
                                my_column: {
                                  exists: true,
                                  data_type: {
                                    value: :integer,
                                    matches: true
                                  },
                                  null: {
                                    value: true,
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
                                    matches: true
                                  },
                                  numeric_precision_radix: {
                                    value: 2,
                                    matches: true
                                  },
                                  numeric_scale: {
                                    value: 0,
                                    matches: true
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
                                    value: true,
                                    matches: true
                                  }
                                }
                              },
                              validations: {},
                              foreign_key_constraints: {},
                              unique_constraints: {}
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
                              description: {
                                value: nil,
                                matches: true
                              },
                              primary_key: {
                                exists: false
                              },
                              columns: {
                                my_column: {
                                  exists: true,
                                  data_type: {
                                    value: :integer,
                                    matches: true
                                  },
                                  null: {
                                    value: true,
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
                                    matches: true
                                  },
                                  numeric_precision_radix: {
                                    value: 2,
                                    matches: true
                                  },
                                  numeric_scale: {
                                    value: 0,
                                    matches: true
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
                                    value: true,
                                    matches: true
                                  }
                                }
                              },
                              validations: {},
                              foreign_key_constraints: {},
                              unique_constraints: {}
                            }
                          }
                        }
                      }
                    })
                  end

                  describe "when the loaded database has an equivalent column" do
                    before(:each) do
                      loaded_table.add_primary_key :my_primary_key, [:my_column]
                    end

                    it "returns the expected differences" do
                      expect(differences.to_h).to eql({
                        configuration: {
                          my_schema: {
                            exists: true,
                            tables: {
                              my_table: {
                                exists: true,
                                description: {
                                  value: nil,
                                  matches: true
                                },
                                primary_key: {
                                  exists: true,
                                  primary_key_name: {
                                    value: :my_primary_key,
                                    matches: true
                                  },
                                  index_type: {
                                    value: :btree,
                                    matches: true
                                  }
                                },
                                columns: {
                                  my_column: {
                                    exists: true,
                                    data_type: {
                                      value: :integer,
                                      matches: true
                                    },
                                    null: {
                                      value: true,
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
                                      matches: true
                                    },
                                    numeric_precision_radix: {
                                      value: 2,
                                      matches: true
                                    },
                                    numeric_scale: {
                                      value: 0,
                                      matches: true
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
                                      value: true,
                                      matches: true
                                    }
                                  }
                                },
                                validations: {},
                                foreign_key_constraints: {},
                                unique_constraints: {}
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
                                description: {
                                  value: nil,
                                  matches: true
                                },
                                primary_key: {
                                  exists: true,
                                  primary_key_name: {
                                    value: :my_primary_key,
                                    matches: true
                                  },
                                  index_type: {
                                    value: :btree,
                                    matches: true
                                  }
                                },
                                columns: {
                                  my_column: {
                                    exists: true,
                                    data_type: {
                                      value: :integer,
                                      matches: true
                                    },
                                    null: {
                                      value: true,
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
                                      matches: true
                                    },
                                    numeric_precision_radix: {
                                      value: 2,
                                      matches: true
                                    },
                                    numeric_scale: {
                                      value: 0,
                                      matches: true
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
                                      value: true,
                                      matches: true
                                    }
                                  }
                                },
                                validations: {},
                                foreign_key_constraints: {},
                                unique_constraints: {}
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
