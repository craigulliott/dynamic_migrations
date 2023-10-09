# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { table.add_column :my_column, :text }
  let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'" }

  describe :initialize do
    it "instantiates a new validation without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'"
      }.to_not raise_error
    end

    describe "providing an optional description" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'", description: "Description of my validation"
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        validation = DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'", description: "Description of my validation"
        expect(validation.description).to eq "Description of my validation"
      end
    end

    describe "providing an optional deferrable value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'", deferrable: true
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        validation = DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'", deferrable: true
        expect(validation.deferrable).to be true
      end
    end

    describe "providing an optional initially_deferred value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'", initially_deferred: true
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        validation = DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'", initially_deferred: true
        expect(validation.initially_deferred).to be true
      end
    end

    it "raises an error if providing an invalid table" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, :not_a_table, [column], :validation_name, "my_column = 'Katy'"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation::ExpectedTableError
    end

    it "raises an error if providing something other than an array for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, :not_an_array, :validation_name, "my_column = 'Katy'"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing an array of objects which are not columns for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [:not_a_column], :validation_name, "my_column = 'Katy'"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing duplicate columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column, column], :validation_name, "my_column = 'Katy'"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation::DuplicateColumnError
    end

    it "raises an error if providing an empty array of columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [], :validation_name, "my_column = 'Katy'"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing something other than a symbol for the validation name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], "invalid validation name", "my_column = 'Katy'"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation::InvalidNameError
    end

    it "raises an error if providing a validation name which is too long" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :this_name_is_too_long_because_it_must_be_under_sixty_four_characters, "my_column = 'Katy'"
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation::InvalidNameError
    end

    it "raises an error if providing something other than a string for the sql check_clause" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, :not_a_string
      }.to raise_error DynamicMigrations::ExpectedStringError
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(validation.table).to eq(table)
    end
  end

  describe :columns do
    it "returns the expected columns" do
      expect(validation.columns).to eql([column])
    end
  end

  describe :column_names do
    it "returns the expected column_names" do
      expect(validation.column_names).to eql([:my_column])
    end

    describe "when no column were added to the validation at instantiation" do
      let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, nil, :validation_name, "my_column = 'Katy'" }

      before(:each) do
        # add the column to the table
        column
      end

      it "returns the expected column_names because it resolves them internally via the `normalized_check_clause_and_column_names` method" do
        expect(validation.column_names).to eql([:my_column])
      end
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(validation.name).to eq(:validation_name)
    end
  end

  describe :check_clause do
    it "returns the expected check_clause" do
      expect(validation.check_clause).to eq("my_column = 'Katy'")
    end
  end

  describe :normalized_check_clause do
    let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'hello'" }

    it "returns the expected normalized check_clause" do
      expect(validation.normalized_check_clause).to eq("(my_column = 'hello'::text)")
    end

    describe "when the validation check_clause contains an emum" do
      let(:enum) { schema.add_enum :my_enum, enum_values, description: "Comment for this enum" }
      let(:enum_values) { ["foo", "bar"] }
      let(:enum_column) { table.add_column :my_column, enum.full_name, enum: enum }
      let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [enum_column], :validation_name, "my_column = 'foo'" }

      it "returns the expected check_clause" do
        expect(validation.normalized_check_clause).to eq("(my_column = 'foo'::my_enum)")
      end
    end

    describe "when the validation check_clause contains an emum with a cast" do
      let(:enum) { schema.add_enum :my_enum, enum_values, description: "Comment for this enum" }
      let(:enum_values) { ["foo", "bar"] }
      let(:enum_column) { table.add_column :my_column, enum.full_name, enum: enum }
      let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [enum_column], :validation_name, "my_column = 'foo'::my_enum" }

      it "returns the expected check_clause" do
        expect(validation.normalized_check_clause).to eq("(my_column = 'foo'::my_enum)")
      end
    end
  end

  describe :deferrable do
    it "returns the expected deferrable" do
      expect(validation.deferrable).to eq(false)
    end
  end

  describe :initially_deferred do
    it "returns the expected initially_deferred" do
      expect(validation.initially_deferred).to eq(false)
    end
  end

  describe :description do
    it "returns the expected description" do
      expect(validation.description).to eq(nil)
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(validation.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:validation_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Katy'", description: "Description of my validation" }
      it "returns true" do
        expect(validation_with_description.has_description?).to be(true)
      end
    end
  end

  describe :differences_descriptions do
    describe "when compared to a validation which has a different normalized_check_clause" do
      let(:different_validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column = 'Yoshimi'" }

      it "returns the expected array which describes the differences" do
        expect(validation.differences_descriptions(different_validation)).to eql([
          "normalized_check_clause changed from `(my_column = 'Katy'::text)` to `(my_column = 'Yoshimi'::text)`"
        ])
      end
    end
  end
end
