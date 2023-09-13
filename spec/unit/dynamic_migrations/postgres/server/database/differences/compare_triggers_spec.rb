# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }

  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:configured_table) { configured_schema.add_table :my_table }
  let(:configured_function) {
    configured_schema.add_function :function_name, <<~SQL
      BEGIN
        NEW.column = 0;
        RETURN NEW;
      END;
    SQL
  }

  let(:loaded_schema) { database.add_loaded_schema :my_schema }
  let(:loaded_table) { loaded_schema.add_table :my_table }
  let(:loaded_function) {
    loaded_schema.add_function :function_name, <<~SQL
      BEGIN
        NEW.column = 0;
        RETURN NEW;
      END;
    SQL
  }

  describe :compare_triggers do
    describe "when base table has no triggers" do
      let(:base) { configured_table }

      describe "when comparison table has no triggers" do
        let(:comparison) { loaded_table }

        it "returns an empty object" do
          expect(differences_class.compare_triggers(base.triggers_hash, comparison.triggers_hash)).to eql({})
        end
      end

      describe "when comparison table has a trigger" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_trigger :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: loaded_function
        end

        it "returns the expected object" do
          expect(differences_class.compare_triggers(base.triggers_hash, comparison.triggers_hash)).to eql({
            trigger_name: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base table has a trigger" do
      let(:base) { configured_table }

      before(:each) do
        base.add_trigger :trigger_name, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: configured_function
      end

      describe "when comparison table has no triggers" do
        let(:comparison) { loaded_table }

        it "returns the expected object" do
          expect(differences_class.compare_triggers(base.triggers_hash, comparison.triggers_hash)).to eql({
            trigger_name: {
              exists: true,
              event_manipulation: {
                value: :insert,
                matches: false
              },
              action_timing: {
                value: :before,
                matches: false
              },
              action_order: {
                value: 1,
                matches: false
              },
              action_condition: {
                value: nil,
                matches: false
              },
              parameters: {
                value: [],
                matches: false
              },
              action_orientation: {
                value: :row,
                matches: false
              },
              action_reference_old_table: {
                value: nil,
                matches: false
              },
              action_reference_new_table: {
                value: nil,
                matches: false
              },
              description: {
                value: nil,
                matches: false
              }
            }
          })
        end
      end

      describe "when comparison table has an equivilent trigger" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_trigger :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: loaded_function
        end

        it "returns the expected object" do
          expect(differences_class.compare_triggers(base.triggers_hash, comparison.triggers_hash)).to eql({
            trigger_name: {
              exists: true,
              event_manipulation: {
                value: :insert,
                matches: true
              },
              action_timing: {
                value: :before,
                matches: true
              },
              action_order: {
                value: 1,
                matches: true
              },
              action_condition: {
                value: nil,
                matches: true
              },
              parameters: {
                value: [],
                matches: true
              },
              action_orientation: {
                value: :row,
                matches: true
              },
              action_reference_old_table: {
                value: nil,
                matches: true
              },
              action_reference_new_table: {
                value: nil,
                matches: true
              },
              description: {
                value: nil,
                matches: true
              }
            }
          })
        end
      end

      describe "when comparison table has a different trigger" do
        let(:comparison) { loaded_table }

        before(:each) do
          comparison.add_trigger :trigger_name, event_manipulation: :insert, action_order: 1, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :after, function: loaded_function
        end

        it "returns the expected object" do
          expect(differences_class.compare_triggers(base.triggers_hash, comparison.triggers_hash)).to eql({
            trigger_name: {
              exists: true,
              event_manipulation: {
                value: :insert,
                matches: true
              },
              action_timing: {
                value: :before,
                matches: false
              },
              action_order: {
                value: 1,
                matches: true
              },
              action_condition: {
                value: nil,
                matches: true
              },
              parameters: {
                value: [],
                matches: true
              },
              action_orientation: {
                value: :row,
                matches: true
              },
              action_reference_old_table: {
                value: nil,
                matches: true
              },
              action_reference_new_table: {
                value: nil,
                matches: true
              },
              description: {
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
          triggers: {
            my_trigger: {
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
          triggers: {
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
            my_trigger: {
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
