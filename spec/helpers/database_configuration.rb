# frozen_string_literal: true

module Helpers
  class DatabaseConfiguration
    class MissingConfigurationError < StandardError
    end

    class ConfigurationNotLoadedError < StandardError
    end

    class MissingRequiredNameError < StandardError
    end

    class MissingRequiredDatabaseTypeError < StandardError
    end

    attr_reader :database, :username, :password, :host, :port

    def initialize database_type, name
      load_configuration_for database_type, name
      @database = require_configuration_value(:database).to_sym
      @host = require_configuration_value :host
      @port = require_configuration_value :port
      @username = require_configuration_value :username
      @password = optional_configuration_value :password
    end

    def to_h
      {
        database: @database,
        host: @host,
        port: @port,
        username: @username,
        password: @password
      }
    end

    def load_configuration_for database_type, name
      raise MissingRequiredNameError unless name
      raise MissingRequiredDatabaseTypeError unless database_type

      @name = name.to_s
      @database_type = database_type.to_s

      configuration = load_configuration_file

      if configuration[@database_type].nil?
        raise MissingConfigurationError, "no database configuration found for #{name} in database.yaml"
      end

      if configuration[@database_type][@name].nil?
        raise MissingConfigurationError, "no configuration found for #{database_type}.#{name} in database.yaml"
      end

      @configuration = configuration[@database_type][@name]
    end

    # returns the configuration value if it exists, else nil
    def optional_configuration_value key
      @configuration[key.to_s]
    end

    # returns the configuration value if it exists, else raises an error
    def require_configuration_value key
      raise ConfigurationNotLoadedError unless @configuration
      @configuration[key.to_s] || raise(MissingConfigurationError, "no `#{key}` found for configuration `#{@name}`")
    end

    # opens the configuration yaml file, and returns the contents as a hash
    def load_configuration_file
      YAML.load_file("config/database.yaml")
    end
  end
end
