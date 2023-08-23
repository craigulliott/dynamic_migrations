# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }

  describe :compare_extensions do
    describe "when base has no extensions" do
      let(:base) { [] }

      describe "when comparison extension has no extensions" do
        let(:comparison) { [] }

        it "returns an empty object" do
          expect(differences_class.compare_extensions(base, comparison)).to eql({})
        end
      end

      describe "when comparison has an extension" do
        let(:comparison) { [:citext] }

        it "returns the expected object" do
          expect(differences_class.compare_extensions(base, comparison)).to eql({
            citext: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base has an extension" do
      let(:base) { [:citext] }

      describe "when comparison has no extensions" do
        let(:comparison) { [] }

        it "returns the expected object" do
          expect(differences_class.compare_extensions(base, comparison)).to eql({
            citext: {
              exists: true
            }
          })
        end
      end

      describe "when comparison has an equivilent extension" do
        let(:comparison) { [:citext] }

        it "returns the expected object" do
          expect(differences_class.compare_extensions(base, comparison)).to eql({
            citext: {
              exists: true
            }
          })
        end
      end

      describe "when comparison has a different extension" do
        let(:comparison) { [:postgis] }

        it "returns the expected object" do
          expect(differences_class.compare_extensions(base, comparison)).to eql({
            citext: {
              exists: true
            },
            postgis: {
              exists: false
            }
          })
        end
      end
    end
  end
end
