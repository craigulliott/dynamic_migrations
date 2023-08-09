# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Schema do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }

    describe :create_schema do
      it "should return the expected ruby syntax to create a schema" do
        expect(generator.create_schema(schema)).to eq <<~RUBY.strip
          create_schema :my_schema
        RUBY
      end
    end

    describe :drop_schema do
      it "should return the expected ruby syntax to drop a schema" do
        expect(generator.drop_schema(schema)).to eq <<~RUBY.strip
          drop_schema :my_schema
        RUBY
      end
    end
  end
end
