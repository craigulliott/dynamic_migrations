# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }

  describe :initialize do
    it "instantiates a new Postgres server without raising an error" do
      expect {
        DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password
      }.to_not raise_error
    end
  end

  describe :add_database do
    it "creates and returns a new database object" do
      expect(server.add_database(:name)).to be_a DynamicMigrations::Postgres::Server::Database
    end

    it "raises an error if providing something other than a symbol" do
      expect {
        server.add_database("name")
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end
  end

  describe :host do
    it "returns the expected host" do
      expect(server.host).to eq(pg_helper.host)
    end
  end

  describe :port do
    it "returns the expected port" do
      expect(server.port).to eq(pg_helper.port)
    end
  end

  describe :username do
    it "returns the expected username" do
      expect(server.username).to eq(pg_helper.username)
    end
  end

  describe :password do
    it "returns the expected password" do
      expect(server.password).to eq(pg_helper.password)
    end
  end

  describe :database do
    it "returns nil" do
      expect(server.database(:name)).to be_nil
    end

    it "raises an error if providing something other than a symbol" do
      expect {
        server.database("name")
      }.to raise_error DynamicMigrations::ExpectedSymbolError
    end

    describe "after a database has been added" do
      before(:each) {
        server.add_database(:name)
      }

      it "returns the expected database" do
        expect(server.database(:name)).to be_a DynamicMigrations::Postgres::Server::Database
        expect(server.database(:name).database_name).to eq(:name)
      end
    end
  end
end
