# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences do
  let(:differences_class) { DynamicMigrations::Postgres::Server::Database::Differences }
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }

  let(:function_definition) {
    <<~SQL
      BEGIN
        NEW.column = 0;
        RETURN NEW;
      END;
    SQL
  }

  let(:configured_schema) { database.add_configured_schema :my_schema }
  let(:configured_function) { configured_schema.add_function :my_function, function_definition }

  let(:loaded_schema) { database.add_loaded_schema :my_schema }
  let(:loaded_function) { loaded_schema.add_function :my_function, function_definition }

  describe :compare_functions do
    describe "when base schema has no functions" do
      let(:base) { configured_schema }

      describe "when comparison schema has no functions" do
        let(:comparison) { loaded_schema }

        it "returns an empty object" do
          expect(differences_class.compare_functions(base.functions_hash, comparison.functions_hash)).to eql({})
        end
      end

      describe "when comparison schema has a function" do
        let(:comparison) { loaded_schema }

        before(:each) do
          comparison.add_function :function_name, function_definition
        end

        it "returns the expected object" do
          expect(differences_class.compare_functions(base.functions_hash, comparison.functions_hash)).to eql({
            function_name: {
              exists: false
            }
          })
        end
      end
    end

    describe "when base schema has a function" do
      let(:base) { configured_schema }

      before(:each) do
        base.add_function :function_name, function_definition
      end

      describe "when comparison schema has no functions" do
        let(:comparison) { loaded_schema }

        it "returns the expected object" do
          expect(differences_class.compare_functions(base.functions_hash, comparison.functions_hash)).to eql({
            function_name: {
              exists: true,
              normalized_definition: {
                value: <<~SQL.strip,
                  BEGIN
                    NEW.column = 0;
                    RETURN NEW;
                  END;
                SQL
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

      describe "when comparison schema has an equivilent function" do
        let(:comparison) { loaded_schema }

        before(:each) do
          comparison.add_function :function_name, function_definition
        end

        it "returns the expected object" do
          expect(differences_class.compare_functions(base.functions_hash, comparison.functions_hash)).to eql({
            function_name: {
              exists: true,
              normalized_definition: {
                value: <<~SQL.strip,
                  BEGIN
                    NEW.column = 0;
                    RETURN NEW;
                  END;
                SQL
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

      describe "when comparison schema has a different function" do
        let(:comparison) { loaded_schema }

        before(:each) do
          different_function_definition = <<~SQL
            BEGIN
              NEW.column = 1;
              RETURN NEW;
            END;
          SQL

          comparison.add_function :function_name, different_function_definition, description: "this function has a description"
        end

        it "returns the expected object" do
          expect(differences_class.compare_functions(base.functions_hash, comparison.functions_hash)).to eql({
            function_name: {
              exists: true,
              normalized_definition: {
                value: <<~SQL.strip,
                  BEGIN
                    NEW.column = 0;
                    RETURN NEW;
                  END;
                SQL
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
