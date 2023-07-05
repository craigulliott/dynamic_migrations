require_relative "postgres_helper/configuration"
require_relative "postgres_helper/connection"
require_relative "postgres_helper/schemas"
require_relative "postgres_helper/tables"
require_relative "postgres_helper/columns"
require_relative "postgres_helper/validations"
require_relative "postgres_helper/foreign_keys"
require_relative "postgres_helper/unique_constraints"
require_relative "postgres_helper/primary_keys"
require_relative "postgres_helper/indexes"
require_relative "postgres_helper/validation_cache"
require_relative "postgres_helper/structure_cache"
require_relative "postgres_helper/foreign_key_cache"
require_relative "postgres_helper/index_cache"

module Helpers
  class PostgresHelper
    include Configuration
    include Connection
    include Schemas
    include Tables
    include Columns
    include Validations
    include ForeignKeys
    include UniqueConstraints
    include PrimaryKeys
    include Indexes
    include ValidationCache
    include StructureCache
    include ForeignKeyCache
    include IndexCache

    attr_reader :database, :username, :password, :host, :port

    def initialize name
      load_configuration_for :postgres, name

      @database = require_configuration_value(:database).to_sym
      @host = require_configuration_value :host
      @port = require_configuration_value :port
      @username = require_configuration_value :username
      @password = optional_configuration_value :password

      # will be set to true if any changes are made to the database structure
      # this is used to determine if the structure needs to be reset between tests
      @has_changes = false
    end

    def has_changes?
      @has_changes
    end

    def reset! force = false
      if force || @has_changes
        delete_all_schemas cascade: true
        # note that the database has been reset and there are no changes
        @has_changes = false
      end
    end
  end
end
