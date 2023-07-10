# frozen_string_literal: true

require "byebug"
require "yaml"
require "dynamic_migrations"
require "pg_spec_helper"
require_relative "helpers/database_configuration"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # the configuration for our test database (loaded from config/database.yaml)
  database_configuration = Helpers::DatabaseConfiguration.new(:postgres, :test).to_h

  # make pg_spec_helper conveniently accessable within our test suite
  config.add_setting :pg_spec_helper
  config.pg_spec_helper = PGSpecHelper.new(**database_configuration)
  # dont modify the postgis schema
  config.pg_spec_helper.ignore_schema :postgis

  # this library uses several materialized_views to cache the structure of
  # the database, we need to refresh them whenever structure changes.
  # Structure cache:
  config.pg_spec_helper.track_materialized_view :public, :dynamic_migrations_structure_cache, [
    :create_schema,
    :create_table,
    :create_column
  ]
  # Keys and unique constraints cache:
  config.pg_spec_helper.track_materialized_view :public, :dynamic_migrations_keys_and_unique_constraints_cache, [
    :delete_all_schemas,
    :delete_tables,
    :create_foreign_key,
    :create_primary_key,
    :create_unique_constraint
  ]
  # Validations cache
  config.pg_spec_helper.track_materialized_view :public, :dynamic_migrations_validations_cache, [
    :delete_all_schemas,
    :delete_tables,
    :create_validation
  ]

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # assert that our test suite is empty before running the test suite
  config.before(:suite) do
    # optionally provide DYNAMIC_MIGRATIONS_CLEAR_DB_ON_STARTUP=true to
    # force reset your database structure
    if ENV["DYNAMIC_MIGRATIONS_CLEAR_DB_ON_STARTUP"]
      config.pg_spec_helper.reset! true
    else
      # raise an error unless the database structure is empty
      config.pg_spec_helper.assert_database_empty!
    end
  end

  # refresh all tracked materialized views before the suite starts
  config.before(:suite) do
    DynamicMigrations::Postgres::Connections.disconnect_all
  end

  # after each spec, disconnect all the open pg connections
  config.after(:each) do
    DynamicMigrations::Postgres::Connections.disconnect_all
  end

  # reset our database structure after each test (this deletes all
  # schemas and tables and then recreates the `public` schema)
  config.after(:each) do
    config.pg_spec_helper.reset!
  end
end
