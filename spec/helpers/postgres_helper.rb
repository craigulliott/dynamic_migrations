require_relative "postgres_helper/configuration"
require_relative "postgres_helper/connection"
require_relative "postgres_helper/schemas"
require_relative "postgres_helper/tables"
require_relative "postgres_helper/columns"

module Helpers
  class PostgresHelper
    include Configuration
    include Connection
    include Schemas
    include Tables
    include Columns

    attr_reader :database, :username, :password, :host, :port

    def initialize name
      load_configuration_for :postgres, name

      @database = require_configuration_value(:database).to_sym
      @host = require_configuration_value :host
      @port = require_configuration_value :port
      @username = require_configuration_value :username
      @password = optional_configuration_value :password
    end
  end
end
