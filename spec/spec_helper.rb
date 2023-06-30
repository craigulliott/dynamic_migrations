# frozen_string_literal: true

require "byebug"
require "yaml"
require "dynamic_migrations"
require_relative "helpers/postgres_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.add_setting :primary_postgres_helper
  config.primary_postgres_helper = Helpers::PostgresHelper.new(:primary)

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    if ENV["DYNAMIC_MIGRATIONS_CLEAR_DB_ON_STARTUP"]
      config.primary_postgres_helper.delete_all_schemas cascade: true
    else
      config.primary_postgres_helper.assert_no_schemas!
    end
  end

  # after each spec, disconnect all the open pg connections
  config.before(:each) do
    DynamicMigrations::Postgres::Connections.disconnect_all
  end

  config.after(:each) do
    config.primary_postgres_helper.reset!
  end
end
