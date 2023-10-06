# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:enum_values) { ["foo", "bar"] }

  describe :Enums do
    describe :add_enum do
      it "creates a new enum object" do
        expect(schema.add_enum(:enum_name, enum_values)).to be_a DynamicMigrations::Postgres::Server::Database::Schema::Enum
      end

      it "raises an error if providing an invalid enum name" do
        expect {
          schema.add_enum "enum_name", enum_values
        }.to raise_error DynamicMigrations::ExpectedSymbolError
      end

      it "raises an error if providing an invalid enum values" do
        expect {
          schema.add_enum :enum_name, 123
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Enum::ExpectedValuesError
      end

      describe "when a enum already exists" do
        before(:each) do
          schema.add_enum(:enum_name, enum_values)
        end

        it "raises an error if using the same enum name" do
          expect {
            schema.add_enum(:enum_name, enum_values)
          }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::EnumAlreadyExistsError
        end
      end
    end

    describe :enum do
      it "raises an error" do
        expect {
          schema.enum(:enum_name)
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::EnumDoesNotExistError
      end

      describe "after the expected enum has been added" do
        let(:enum) { schema.add_enum :enum_name, enum_values }

        before(:each) do
          enum
        end

        it "returns the enum" do
          expect(schema.enum(:enum_name)).to eq(enum)
        end
      end
    end

    describe :has_enum? do
      it "returns false" do
        expect(schema.has_enum?(:enum_name)).to be(false)
      end

      describe "after the expected enum has been added" do
        let(:enum) { schema.add_enum :enum_name, enum_values }

        before(:each) do
          enum
        end

        it "returns true" do
          expect(schema.has_enum?(:enum_name)).to be(true)
        end
      end
    end

    describe :enums do
      it "returns an empty array" do
        expect(schema.enums).to be_an Array
        expect(schema.enums).to be_empty
      end

      describe "after the expected enum has been added" do
        let(:enum) { schema.add_enum :enum_name, enum_values }

        before(:each) do
          enum
        end

        it "returns an array of the expected enums" do
          expect(schema.enums).to eql([enum])
        end
      end
    end

    describe :enums_hash do
      it "returns an empty hash" do
        expect(schema.enums_hash).to eql({})
      end

      describe "after the expected enum has been added" do
        let(:enum) { schema.add_enum :enum_name, enum_values }

        before(:each) do
          enum
        end

        it "returns a hash representation of the expected enums" do
          expect(schema.enums_hash).to eql({enum_name: enum})
        end
      end
    end
  end
end
