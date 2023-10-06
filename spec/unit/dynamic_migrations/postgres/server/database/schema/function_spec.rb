# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Function do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:function) { DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, function_definition }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:function_definition) {
    <<~SQL
      BEGIN
        NEW.column = 0;
        RETURN NEW;
      END;
    SQL
  }

  describe :initialize do
    it "instantiates a new function without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, function_definition
      }.to_not raise_error
    end

    it "raises an error if providing an invalid schema" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, "not a schema object", :my_function, function_definition
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Function::ExpectedSchemaError
    end

    it "raises an error if providing an invalid function name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, "my_function", function_definition
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    it "raises an error if providing an invalid definition" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, 123
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Function::ExpectedDefinitionError
    end

    describe "when providing an optional description" do
      it "instantiates a new function without raising an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, function_definition, description: "a valid description of my function"
        }.to_not raise_error
      end

      it "raises an error if providing an invalid description" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, function_definition, description: :an_invalid_description_type
        }.to raise_error DynamicMigrations::ExpectedStringError
      end
    end
  end

  describe :schema do
    it "returns the expected schema" do
      expect(function.schema).to eq(schema)
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(function.name).to eq(:my_function)
    end
  end

  describe :definition do
    it "returns the expected definition" do
      expect(function.definition).to eq(<<~SQL.strip)
        BEGIN
          NEW.column = 0;
          RETURN NEW;
        END;
      SQL
    end
  end

  describe :normalized_definition do
    it "returns the expected normalized_definition" do
      expect(function.normalized_definition).to eq(<<~SQL.strip)
        BEGIN
          NEW.column = 0;
          RETURN NEW;
        END;
      SQL
    end
  end

  describe :triggers do
    it "returns an empty array because no triggers have been added" do
      expect(function.triggers).to eql []
    end

    describe "after a trigger has been added which references this function" do
      let(:trigger) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Trigger.new :configuration, table, :trigger_name, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: function }

      before(:each) do
        trigger
      end

      it "returns the expected triggers" do
        expect(function.triggers).to eql([trigger])
      end
    end
  end

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(function.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:function_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, function_definition, description: "a valid description of my function" }
      it "returns the expected description" do
        expect(function_with_description.description).to eq("a valid description of my function")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(function.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:function_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, function_definition, description: "a valid description of my function" }
      it "returns true" do
        expect(function_with_description.has_description?).to be(true)
      end
    end
  end

  describe :add_trigger do
    # Can not directly test this method because it is called automatically when
    # a trigger is instantiated. The trigger specs adequately cover this method.
  end

  describe :differences_descriptions do
    describe "when compared to a function which has a different definition" do
      let(:different_function) {
        DynamicMigrations::Postgres::Server::Database::Schema::Function.new :configuration, schema, :my_function, <<~SQL
          BEGIN
            NEW.different_column = 0;
            RETURN NEW;
          END;
        SQL
      }

      it "returns the expected array which describes the differences" do
        expect(function.differences_descriptions(different_function)).to eql([
          <<~CHANGES.strip
            normalized_definition changed from `BEGIN
              NEW.column = 0;
              RETURN NEW;
            END;` to `BEGIN
              NEW.different_column = 0;
              RETURN NEW;
            END;`
          CHANGES
        ])
      end
    end
  end

  describe :normalized_definition do
    it "returns the expected definition" do
      expect(function.normalized_definition).to eq(<<~SQL.strip)
        BEGIN
          NEW.column = 0;
          RETURN NEW;
        END;
      SQL
    end
  end
end
