module DynamicMigrations
  class InvalidSourceError < StandardError
    def initialize source
      super "expected :configuration or :database but got #{source}"
    end
  end
end
