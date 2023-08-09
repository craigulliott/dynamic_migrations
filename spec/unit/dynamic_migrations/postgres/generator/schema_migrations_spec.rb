todo
# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator::SchemaMigrations do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
  let(:generator) { DynamicMigrations::Postgres::Generator::SchemaMigrations.new }

  describe :initialize do
    it "" do
      raise "todo"
    end
  end
end
