module Helpers
  class PostgresHelper
    module Configuration
      class MissingConfigurationError < StandardError
      end

      class ConfigurationNotLoadedError < StandardError
      end

      class MissingRequiredNameError < StandardError
      end

      class MissingRequiredDatabaseTypeError < StandardError
      end

      def load_configuration_for database_type, name
        @name = name.to_s
        @database_type = database_type.to_s

        raise MissingRequiredNameError unless @name
        raise MissingRequiredDatabaseTypeError unless @database_type

        configuration = load_configuration_file

        if configuration[@database_type].nil?
          raise MissingConfigurationError, "no database configuration found for #{name} in database.yaml"
        end

        if configuration[@database_type][@name].nil?
          raise MissingConfigurationError, "no configuration found for #{database_type}.#{name} in database.yaml"
        end

        @configuration = configuration[@database_type][@name]
      end

      def optional_configuration_value key
        @configuration[key.to_s]
      end

      def require_configuration_value key
        raise ConfigurationNotLoadedError unless @configuration

        @configuration[key.to_s] || raise(MissingConfigurationError, "no #{key} found for configuration #{@database_type}.#{@name}")
      end

      def load_configuration_file
        YAML.load_file("config/database.yaml")
      end
    end
  end
end
