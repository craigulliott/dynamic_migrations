# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    # The default behaviour of dynamic migrations is to generate migrations
    # which remove any unused extensions.
    # People don't always have control over which extensions are running on the
    # database, so this behaviour can be disabled by setting
    # `DynamicMigrations::Postgres.remove_unused_extensions = false`
    def self.remove_unused_extensions= value
      @remove_unused_extensions = value
    end

    # defaults to true, but can be set to false to disable the removal of unused
    # extensions
    def self.remove_unused_extensions?
      (@remove_unused_extensions.nil? || @remove_unused_extensions) ? true : false
    end

    # Dynamic Migrations creates a materialized view to store a cache representation
    # of various parts of the database structure, by default this is created in the
    # public schema, but this can be changed by setting the otion below.
    def self.cache_schema_name= value
      @cache_schema_name = value
    end

    # defaults to true, but can be set to false to disable the removal of unused
    # extensions
    def self.cache_schema_name
      @cache_schema_name || :public
    end
  end
end
