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
  end
end
