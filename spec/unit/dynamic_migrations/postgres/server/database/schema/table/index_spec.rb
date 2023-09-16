# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Schema::Table::Index do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table }
  let(:column) { table.add_column :my_column, :boolean }
  let(:column2) { table.add_column :my_other_column, :boolean }
  let(:index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name }

  describe :initialize do
    it "instantiates a new index without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name
      }.to_not raise_error
    end

    describe "providing an optional description" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, description: "foo bar"
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        index = DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, description: "foo bar"
        expect(index.description).to eq "foo bar"
      end
    end

    describe "providing an optional unique value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, unique: true
        }.to_not raise_error
      end

      it "raises an error if providing an unexpected index unique" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, unique: :unexpected_unique_value
        }.to raise_error DynamicMigrations::ExpectedBooleanError
      end

      it "returns the expected value via a getter of the same name" do
        index = DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, unique: true
        expect(index.unique).to be true
      end
    end

    describe "providing an optional where value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, where: "my_column IS TRIUE"
        }.to_not raise_error
      end

      it "raises an error if providing an unexpected index where" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, where: :unexpected_where_value
        }.to raise_error DynamicMigrations::ExpectedStringError
      end

      it "returns the expected value via a getter of the same name" do
        index = DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, where: "my_column IS TRIUE"
        expect(index.where).to eq "my_column IS TRIUE"
      end
    end

    describe "providing an optional type value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, type: :gist
        }.to_not raise_error
      end

      it "raises an error if providing an unexpected index type" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, type: :type
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::UnexpectedIndexTypeError
      end

      it "returns the expected value via a getter of the same name" do
        index = DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, type: :gist
        expect(index.type).to be :gist
      end
    end

    describe "providing an optional include_columns value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, include_columns: [column2]
        }.to_not raise_error
      end

      describe "for an index which has include_columns set" do
        let(:index_with_include_columns) do
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, include_columns: [column2]
        end

        it "returns the expected value via a getter of the same name" do
          expect(index_with_include_columns.include_columns).to eql([column2])
        end

        it "returns an array of only the names via the expected getter" do
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, include_columns: [column2]
          expect(index_with_include_columns.include_column_names).to eql([:my_other_column])
        end
      end

      it "raises an error if providing something other than an array for columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, include_columns: :not_an_array
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::ExpectedArrayOfColumnsError
      end

      it "raises an error if providing an array of objects which are not columns for columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, include_columns: [:not_a_column]
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::ExpectedArrayOfColumnsError
      end

      it "raises an error if providing duplicate columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, include_columns: [column2, column2]
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::DuplicateColumnError
      end

      it "raises an error if providing columns which overlap with the main indexes columns" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, include_columns: [column]
        }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::DuplicateColumnError
      end
    end

    describe "providing an optional order value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, order: :desc
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        index = DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, order: :desc
        expect(index.order).to be :desc
      end
    end

    describe "providing an optional nulls_position value" do
      it "does not raise an error" do
        expect {
          DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, nulls_position: :first
        }.to_not raise_error
      end

      it "returns the expected value via a getter of the same name" do
        index = DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, nulls_position: :first
        expect(index.nulls_position).to be :first
      end
    end

    it "raises an error if providing an invalid table" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, :not_a_table, [column], :index_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::ExpectedTableError
    end

    it "raises an error if providing something other than an array for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, :not_an_array, :index_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing an array of objects which are not columns for columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [:not_a_column], :index_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing duplicate columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column, column], :index_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::DuplicateColumnError
    end

    it "raises an error if providing an empty array of columns" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [], :index_name
      }.to raise_error DynamicMigrations::Postgres::Server::Database::Schema::Table::Index::ExpectedArrayOfColumnsError
    end

    it "raises an error if providing something other than a symbol for the index name" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], "invalid index name"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end
  end

  describe :table do
    it "returns the expected table" do
      expect(index.table).to eq(table)
    end
  end

  describe :columns do
    it "returns the expected columns" do
      expect(index.columns).to eql([column])
    end
  end

  describe :column_names do
    it "returns the expected columns" do
      expect(index.column_names).to eql([:my_column])
    end
  end

  describe :name do
    it "returns the expected name" do
      expect(index.name).to eq(:index_name)
    end
  end

  describe :unique do
    it "returns the expected unique" do
      expect(index.unique).to eq(false)
    end
  end

  describe :where do
    it "returns the expected where" do
      expect(index.where).to eq(nil)
    end
  end

  describe :type do
    it "returns the expected type" do
      expect(index.type).to eq(:btree)
    end
  end

  describe :include_columns do
    it "returns the expected include_columns" do
      expect(index.include_columns).to eql([])
    end
  end

  describe :include_column_names do
    it "returns the expected include_column names" do
      expect(index.include_column_names).to eql([])
    end
  end

  describe :order do
    it "returns the expected order" do
      expect(index.order).to eq(:asc)
    end
  end

  describe :nulls_position do
    it "returns the expected nulls_position" do
      expect(index.nulls_position).to eq(:last)
    end
  end

  describe :description do
    describe "when no description was provided at initialization" do
      it "returns nil" do
        expect(index.description).to be_nil
      end
    end

    describe "when a description was provided at initialization" do
      let(:index_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, description: "foo bar" }
      it "returns the expected description" do
        expect(index_with_description.description).to eq("foo bar")
      end
    end
  end

  describe :has_description? do
    describe "when no description was provided at initialization" do
      it "returns false" do
        expect(index.has_description?).to be(false)
      end
    end

    describe "when a description was provided at initialization" do
      let(:index_with_description) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, description: "foo bar" }
      it "returns true" do
        expect(index_with_description.has_description?).to be(true)
      end
    end
  end

  describe :differences_descriptions do
    describe "when compared to a index which has differnt values for unique, order and nulls_position" do
      let(:different_index) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Index.new :configuration, table, [column], :index_name, unique: true, order: :desc, nulls_position: :first }

      it "returns the expected array which describes the differences" do
        expect(index.differences_descriptions(different_index)).to eql([
          "unique changed from `false` to `true`",
          "order changed from `asc` to `desc`",
          "nulls_position changed from `last` to `first`"
        ])
      end
    end
  end
end
