# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }

  let(:enum_values) { [:foo, :bar] }

  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:configured_enum) { configured_schema.add_enum :my_enum, enum_values }

  let(:loaded_schema) { database.add_loaded_schema :my_schema }
  let(:loaded_enum) { loaded_schema.add_enum :my_enum, enum_values }

  describe :compare_enums do
    describe "when base schema has no enums" do
      let(:base) { configured_schema }

      describe "when comparison schema has no enums" do
        let(:comparison) { loaded_schema }

        it "returns an empty object" do
          expect(differences_class.compare_enums(base.enums_hash, comparison.enums_hash)).to eql({})
        end
      end

      describe "when comparison schema has a enum" do
        let(:comparison) { loaded_schema }

        before(:each) do
          comparison.add_enum :enum_name, enum_values
        end

        it "returns the expected object" do
          expect(differences_class.compare_enums(base.enums_hash, comparison.enums_hash)).to eql({
            enum_name: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base schema has a enum" do
      let(:base) { configured_schema }

      before(:each) do
        base.add_enum :enum_name, enum_values
      end

      describe "when comparison schema has no enums" do
        let(:comparison) { loaded_schema }

        it "returns the expected object" do
          expect(differences_class.compare_enums(base.enums_hash, comparison.enums_hash)).to eql({
            enum_name: {
              exists: true,
              values: {
                value: [
                  :foo,
                  :bar
                ],
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

      describe "when comparison schema has an equivilent enum" do
        let(:comparison) { loaded_schema }

        before(:each) do
          comparison.add_enum :enum_name, enum_values
        end

        it "returns the expected object" do
          expect(differences_class.compare_enums(base.enums_hash, comparison.enums_hash)).to eql({
            enum_name: {
              exists: true,
              values: {
                value: [
                  :foo,
                  :bar
                ],
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

      describe "when comparison schema has a different enum" do
        let(:comparison) { loaded_schema }

        before(:each) do
          different_enum_values = [
            :foo,
            :baz
          ]

          comparison.add_enum :enum_name, different_enum_values, description: "this enum has a description"
        end

        it "returns the expected object" do
          expect(differences_class.compare_enums(base.enums_hash, comparison.enums_hash)).to eql({
            enum_name: {
              exists: true,
              values: {
                value: [
                  :foo,
                  :bar
                ],
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
    end
  end
end
