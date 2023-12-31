# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
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

  describe :to_migrations do
    it "returns an empty object because there are no differences" do
      expect(differences.to_migrations).to eql([])
    end

    describe "when the configured database has a schema" do
      let(:configured_schema) { database.add_configured_schema :my_schema }

      before(:each) do
        configured_schema
      end

      it "returns the expected migrations" do
        expect(differences.to_migrations).to eql([
          {
            schema_name: nil,
            name: :create_my_schema_schema,
            content: <<~RUBY.strip
              #
              # Create this schema
              #
              create_schema :my_schema
            RUBY
          }
        ])
      end

      describe "when the loaded database has an equivalent schema" do
        let(:loaded_schema) { database.add_loaded_schema :my_schema }

        before(:each) do
          loaded_schema
        end

        it "returns an empty object because there are no differences" do
          expect(differences.to_migrations).to eql([])
        end

        describe "when the configured schema has a table" do
          let(:configured_table) { configured_schema.add_table :my_table, description: "Description of my table" }

          before(:each) do
            configured_table
          end

          it "returns the expected migrations" do
            expect(differences.to_migrations).to eql([
              {
                schema_name: :my_schema,
                name: :create_my_table,
                content: <<~RUBY.strip
                  #
                  # Create Table
                  #
                  table_comment = <<~COMMENT
                    Description of my table
                  COMMENT
                  create_table :my_table, id: false, comment: table_comment do |t|

                  end
                RUBY
              }
            ])
          end

          describe "when the loaded database has an equivalent table" do
            let(:loaded_table) { loaded_schema.add_table :my_table, description: "Description of my table" }

            before(:each) do
              loaded_table
            end

            it "returns an empty object because there are no differences" do
              expect(differences.to_migrations).to eql([])
            end

            describe "when the configured table has a column" do
              before(:each) do
                configured_table.add_column :my_column, :integer
              end
            end
          end
        end
      end
    end
  end

  describe :to_h do
    it "returns the expected differences" do
      expect(differences.to_h).to eql({
        configuration: {
          schemas: {},
          extensions: {}
        },
        database: {
          schemas: {},
          extensions: {}
        }
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
            schemas: {
              my_schema: {
                exists: true,
                tables: {},
                enums: {},
                functions: {}
              }
            },
            extensions: {}
          },
          database: {
            schemas: {
              my_schema: {
                exists: false
              }
            },
            extensions: {}
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
              schemas: {
                my_schema: {
                  exists: true,
                  tables: {},
                  enums: {},
                  functions: {}
                }
              },
              extensions: {}
            },
            database: {
              schemas: {
                my_schema: {
                  exists: true,
                  tables: {},
                  enums: {},
                  functions: {}
                }
              },
              extensions: {}
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
                schemas: {
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
                        indexes: {},
                        triggers: {},
                        validations: {},
                        foreign_key_constraints: {},
                        unique_constraints: {}
                      }
                    },
                    enums: {},
                    functions: {}
                  }
                },
                extensions: {}
              },
              database: {
                schemas: {
                  my_schema: {
                    exists: true,
                    tables: {
                      my_table: {
                        exists: false
                      }
                    },
                    enums: {},
                    functions: {}
                  }
                },
                extensions: {}
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
                  schemas: {
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
                          indexes: {},
                          triggers: {},
                          validations: {},
                          foreign_key_constraints: {},
                          unique_constraints: {}

                        }
                      },
                      enums: {},
                      functions: {}
                    }
                  },
                  extensions: {}
                },
                database: {
                  schemas: {
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
                          indexes: {},
                          triggers: {},
                          validations: {},
                          foreign_key_constraints: {},
                          unique_constraints: {}
                        }
                      },
                      enums: {},
                      functions: {}
                    }
                  },
                  extensions: {}

                }
              })
            end

            describe "when the configured table has a column" do
              before(:each) do
                configured_table.add_column :my_column, :integer
              end

              it "returns the expected differences" do
                expect(differences.to_h).to eql({
                  configuration: {
                    schemas: {
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
                                interval_type: {
                                  value: nil,
                                  matches: false
                                }
                              }
                            },
                            indexes: {},
                            triggers: {},
                            validations: {},
                            foreign_key_constraints: {},
                            unique_constraints: {}
                          }
                        },
                        enums: {},
                        functions: {}
                      }
                    },
                    extensions: {}
                  },
                  database: {
                    schemas: {
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
                            indexes: {},
                            triggers: {},
                            validations: {},
                            foreign_key_constraints: {},
                            unique_constraints: {}
                          }
                        },
                        enums: {},
                        functions: {}
                      }
                    },
                    extensions: {}
                  }
                })
              end

              describe "when the loaded database has an equivalent column" do
                before(:each) do
                  loaded_table.add_column :my_column, :integer
                end

                it "returns the expected differences" do
                  expect(differences.to_h).to eql({
                    configuration: {
                      schemas: {
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
                                  interval_type: {
                                    value: nil,
                                    matches: true
                                  }
                                }
                              },
                              indexes: {},
                              triggers: {},
                              validations: {},
                              foreign_key_constraints: {},
                              unique_constraints: {}
                            }
                          },
                          enums: {},
                          functions: {}
                        }
                      },
                      extensions: {}
                    },
                    database: {
                      schemas: {
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
                                  interval_type: {
                                    value: nil,
                                    matches: true
                                  }
                                }
                              },
                              indexes: {},
                              triggers: {},
                              validations: {},
                              foreign_key_constraints: {},
                              unique_constraints: {}
                            }
                          },
                          enums: {},
                          functions: {}
                        }
                      },
                      extensions: {}
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
                        schemas: {
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
                                  name: {
                                    value: :my_primary_key,
                                    matches: false
                                  },
                                  column_names: {
                                    value: [:my_column],
                                    matches: false
                                  },
                                  description: {
                                    value: nil,
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
                                    interval_type: {
                                      value: nil,
                                      matches: true
                                    }
                                  }
                                },
                                indexes: {},
                                triggers: {},
                                validations: {},
                                foreign_key_constraints: {},
                                unique_constraints: {}
                              }
                            },
                            enums: {},
                            functions: {}
                          }
                        },
                        extensions: {}
                      },
                      database: {
                        schemas: {
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
                                    interval_type: {
                                      value: nil,
                                      matches: true
                                    }
                                  }
                                },
                                indexes: {},
                                triggers: {},
                                validations: {},
                                foreign_key_constraints: {},
                                unique_constraints: {}
                              }
                            },
                            enums: {},
                            functions: {}
                          }
                        },
                        extensions: {}

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
                          schemas: {
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
                                    name: {
                                      value: :my_primary_key,
                                      matches: true
                                    },
                                    column_names: {
                                      value: [:my_column],
                                      matches: true
                                    },
                                    description: {
                                      value: nil,
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
                                      interval_type: {
                                        value: nil,
                                        matches: true
                                      }
                                    }
                                  },
                                  indexes: {},
                                  triggers: {},
                                  validations: {},
                                  foreign_key_constraints: {},
                                  unique_constraints: {}
                                }
                              },
                              enums: {},
                              functions: {}
                            }
                          },
                          extensions: {}
                        },
                        database: {
                          schemas: {
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
                                    name: {
                                      value: :my_primary_key,
                                      matches: true
                                    },
                                    column_names: {
                                      value: [:my_column],
                                      matches: true
                                    },
                                    description: {
                                      value: nil,
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
                                      interval_type: {
                                        value: nil,
                                        matches: true
                                      }
                                    }
                                  },
                                  indexes: {},
                                  triggers: {},
                                  validations: {},
                                  foreign_key_constraints: {},
                                  unique_constraints: {}
                                }
                              },
                              enums: {},
                              functions: {}
                            }
                          },
                          extensions: {}
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
