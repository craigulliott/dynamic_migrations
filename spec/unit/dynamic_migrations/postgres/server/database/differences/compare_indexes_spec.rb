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

  describe :compare_indexes do
    describe "when base table has no indexes" do
      let(:base) { configured_table }

      describe "when comparison table has no indexes" do
        let(:comparison) { loaded_table }

        it "returns an empty object" do
          expect(differences_class.compare_indexes(base.indexes_hash, comparison.indexes_hash)).to eql({})
        end
      end

      describe "when comparison table has a index" do
        let(:comparison) { loaded_table }

        before(:each) {
          comparison.add_column :column_name, :boolean
          comparison.add_index :index_name, [:column_name]
        }

        it "returns the expected object" do
          expect(differences_class.compare_indexes(base.indexes_hash, comparison.indexes_hash)).to eql({
            index_name: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base table has a index" do
      let(:base) { configured_table }

      before(:each) {
        base.add_column :column_name, :boolean
        base.add_index :index_name, [:column_name]
      }

      describe "when comparison table has no indexes" do
        let(:comparison) { loaded_table }

        it "returns the expected object" do
          expect(differences_class.compare_indexes(base.indexes_hash, comparison.indexes_hash)).to eql({
            index_name: {
              exists: true,
              column_names: {
                value: [:column_name],
                matches: false
              },
              unique: {
                value: false,
                matches: false
              },
              where: {
                value: nil,
                matches: false
              },
              type: {
                value: :btree,
                matches: false
              },
              deferrable: {
                value: false,
                matches: false
              },
              initially_deferred: {
                value: false,
                matches: false
              },
              order: {
                value: :asc,
                matches: false
              },
              nulls_position: {
                value: :last,
                matches: false
              }
            }
          })
        end
      end

      describe "when comparison table has an equivilent index" do
        let(:comparison) { loaded_table }

        before(:each) {
          comparison.add_column :column_name, :boolean
          comparison.add_index :index_name, [:column_name]
        }

        it "returns the expected object" do
          expect(differences_class.compare_indexes(base.indexes_hash, comparison.indexes_hash)).to eql({
            index_name: {
              exists: true,
              column_names: {
                value: [:column_name],
                matches: true
              },
              unique: {
                value: false,
                matches: true
              },
              where: {
                value: nil,
                matches: true
              },
              type: {
                value: :btree,
                matches: true
              },
              deferrable: {
                value: false,
                matches: true
              },
              initially_deferred: {
                value: false,
                matches: true
              },
              order: {
                value: :asc,
                matches: true
              },
              nulls_position: {
                value: :last,
                matches: true
              }
            }
          })
        end
      end

      describe "when comparison table has a different index" do
        let(:comparison) { loaded_table }

        before(:each) {
          comparison.add_column :column_name, :boolean
          comparison.add_index :index_name, [:column_name], where: "column_name IS TRUE", type: :gin
        }

        it "returns the expected object" do
          expect(differences_class.compare_indexes(base.indexes_hash, comparison.indexes_hash)).to eql({
            index_name: {
              exists: true,
              column_names: {
                value: [:column_name],
                matches: true
              },
              unique: {
                value: false,
                matches: true
              },
              where: {
                value: nil,
                matches: false
              },
              type: {
                value: :btree,
                matches: false
              },
              deferrable: {
                value: false,
                matches: true
              },
              initially_deferred: {
                value: false,
                matches: true
              },
              order: {
                value: :asc,
                matches: true
              },
              nulls_position: {
                value: :last,
                matches: true
              }
            }
          })
        end
      end
    end
  end
end
