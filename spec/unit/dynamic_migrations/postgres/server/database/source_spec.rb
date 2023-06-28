# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Source do
  let(:configuration_source) { DynamicMigrations::Postgres::Server::Database::Source.new :configuration }
  let(:database_source) { DynamicMigrations::Postgres::Server::Database::Source.new :database }

  describe :initialize do
    it "instantiates configuration source without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Source.new :configuration
      }.to_not raise_error
    end

    it "instantiates database source without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Source.new :database
      }.to_not raise_error
    end

    it "raises an error if providing an invalid source" do
      expect {
        DynamicMigrations::Postgres::Server::Database::Source.new :invalid
      }.to raise_error DynamicMigrations::InvalidSourceError
    end
  end

  describe :source do
    describe "for a configuration source" do
      it "returns the expected source" do
        expect(configuration_source.source).to eq(:configuration)
      end
    end

    describe "for a database source" do
      it "returns the expected source" do
        expect(database_source.source).to eq(:database)
      end
    end
  end

  describe :from_configuration? do
    describe "for a configuration source" do
      it "returns a boolean representing if the source is set to :configuration" do
        expect(configuration_source.from_configuration?).to eq(true)
      end
    end

    describe "for a database source" do
      it "returns a boolean representing if the source is set to :configuration" do
        expect(database_source.from_configuration?).to eq(false)
      end
    end
  end

  describe :from_database? do
    describe "for a configuration source" do
      it "returns a boolean representing if the source is set to :database" do
        expect(configuration_source.from_database?).to eq(false)
      end
    end

    describe "for a database source" do
      it "returns a boolean representing if the source is set to :database" do
        expect(database_source.from_database?).to eq(true)
      end
    end
  end

  describe :assert_is_a_symbol! do
    it "returns true for a symbol" do
      expect(configuration_source.assert_is_a_symbol!(:this_is_a_symbol)).to eq(true)
    end

    it "raises an error for a non-symbol" do
      expect {
        configuration_source.assert_is_a_symbol! "this_is_not_a_symbol"
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end
  end
end
