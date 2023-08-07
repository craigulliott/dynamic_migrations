# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }

  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:configured_table) { configured_schema.add_table :my_table }

  let(:loaded_schema) { database.add_loaded_schema :my_schema }
  let(:loaded_table) { loaded_schema.add_table :my_table }

  describe :compare_columns do
    describe "when base table has no columns" do
      let(:base) { configured_table }

      describe "when comparison table has no columns" do
        let(:comparison) { loaded_table }

        it "returns an empty object" do
          expect(differences_class.compare_columns(base.columns_hash, comparison.columns_hash)).to eql({})
        end
      end

      describe "when comparison table has a column" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :integer
        end

        it "returns the expected object" do
          expect(differences_class.compare_columns(base.columns_hash, comparison.columns_hash)).to eql({
            column_name: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base table has a column" do
      let(:base) { configured_table }

      before(:each) do
        base.add_column :column_name, :boolean
      end

      describe "when comparison table has no columns" do
        let(:comparison) { loaded_table }

        it "returns the expected object" do
          expect(differences_class.compare_columns(base.columns_hash, comparison.columns_hash)).to eql({
            column_name: {
              exists: true,
              data_type: {
                value: :boolean,
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
          })
        end
      end

      describe "when comparison table has an equivilent column" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :boolean
        end

        it "returns the expected object" do
          expect(differences_class.compare_columns(base.columns_hash, comparison.columns_hash)).to eql({
            column_name: {
              exists: true,
              data_type: {
                value: :boolean,
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
          })
        end
      end

      describe "when comparison table has a different column" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_column :column_name, :character
        end

        it "returns the expected object" do
          expect(differences_class.compare_columns(base.columns_hash, comparison.columns_hash)).to eql({
            column_name: {
              exists: true,
              data_type: {
                value: :boolean,
                matches: false
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
          })
        end
      end
    end
  end
end

{
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
              interval_type: {
                value: nil,
                matches: false
              }
            },
            a: {
              exists: false
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
            a: {
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
            },
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
}
