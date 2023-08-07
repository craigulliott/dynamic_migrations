# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }

  describe :Functions do
    describe :add_function do
      it "creates a new function object" do
        expect(schema.add_function(:function_name, "NEW.column = 0")).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Function
      end

      it "raises an error if providing an invalid function name" do
        expect {
          schema.add_function "function_name", "NEW.column = 0"
        }.to raise_error DynamicMigrations::ExpectedSymbolError
      end

      it "raises an error if providing an invalid function definition" do
        expect {
          schema.add_function :function_name, 123
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Function::ExpectedDefinitionError
      end

      describe "when a function already exists" do
        before(:each) do
          schema.add_function(:function_name, "NEW.column = 0")
        end

        it "raises an error if using the same function name" do
          expect {
            schema.add_function(:function_name, "NEW.column = 0")
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::FunctionAlreadyExistsError
        end
      end
    end

    describe :function do
      it "raises an error" do
        expect {
          schema.function(:function_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::FunctionDoesNotExistError
      end

      describe "after the expected function has been added" do
        let(:function) { schema.add_function :function_name, "NEW.column = 0" }

        before(:each) do
          function
        end

        it "returns the function" do
          expect(schema.function(:function_name)).to eq(function)
        end
      end
    end

    describe :has_function? do
      it "returns false" do
        expect(schema.has_function?(:function_name)).to be(false)
      end

      describe "after the expected function has been added" do
        let(:function) { schema.add_function :function_name, "NEW.column = 0" }

        before(:each) do
          function
        end

        it "returns true" do
          expect(schema.has_function?(:function_name)).to be(true)
        end
      end
    end

    describe :functions do
      it "returns an empty array" do
        expect(schema.functions).to be_an Array
        expect(schema.functions).to be_empty
      end

      describe "after the expected function has been added" do
        let(:function) { schema.add_function :function_name, "NEW.column = 0" }

        before(:each) do
          function
        end

        it "returns an array of the expected functions" do
          expect(schema.functions).to eql([function])
        end
      end
    end

    describe :functions_hash do
      it "returns an empty hash" do
        expect(schema.functions_hash).to eql({})
      end

      describe "after the expected function has been added" do
        let(:function) { schema.add_function :function_name, "NEW.column = 0" }

        before(:each) do
          function
        end

        it "returns a hash representation of the expected functions" do
          expect(schema.functions_hash).to eql({function_name: function})
        end
      end
    end
  end
end
