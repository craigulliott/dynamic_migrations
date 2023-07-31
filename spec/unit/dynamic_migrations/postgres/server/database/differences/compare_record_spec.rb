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

  describe :compare_record do
    describe "comparing columns (a method list for column objects)" do
      let(:method_list) {
        [
          :data_type,
          :null,
          :default,
          :description,
          :interval_type
        ]
      }

      describe "when base is nil" do
        let(:base) { nil }

        describe "when comparison is nil" do
          let(:comparison) { nil }

          it "returns exists: false" do
            expect(differences_class.compare_record(base, comparison, method_list)).to eql({
              exists: false
            })
          end
        end
      end

      describe "when base is a column object" do
        let(:base) { configured_table.add_column :column_name, :integer }

        describe "when comparison is nil" do
          let(:comparison) { nil }

          it "returns the expected hash" do
            expect(differences_class.compare_record(base, comparison, method_list)).to eql({
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
            })
          end
        end

        describe "when comparison is equivilent" do
          let(:comparison) { loaded_table.add_column :column_name, :integer }

          it "returns the expected hash" do
            expect(differences_class.compare_record(base, comparison, method_list)).to eql({
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
            })
          end
        end

        describe "when comparison has differences" do
          let(:comparison) { loaded_table.add_column :column_name, :character }

          it "returns the expected hash" do
            expect(differences_class.compare_record(base, comparison, method_list)).to eql({
              exists: true,
              data_type: {
                value: :integer,
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
            })
          end
        end
      end
    end
  end
end
