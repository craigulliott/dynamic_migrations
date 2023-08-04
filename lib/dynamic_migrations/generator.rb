module DynamicMigrations
  class Generator
    class ExpectedSymbolError < StandardError
    end

    class DeferrableOptionsError < StandardError
    end

    include Schema
    include Table
    include Column
    include ForeignKeyConstraint
    include Index
    include PrimaryKey
    include UniqueConstraint
    include Validation
    include FixIndentation

    def initialize
      @migrations = {}
    end

    # builds an array of migrations that can be used to create the provided schema
    def schema_migrations schema_name
      raise ExpectedSymbolError, "Expected schema_name to be a symbol, got #{schema_name}" unless schema_name.is_a?(Symbol)

      @migrations[schema_name] ||= {}
      # an array of table names which have migrations, we group migrations for the same table together
      table_names = @migrations[schema_name].keys
      table_names.map do |table_name|
        {
          name: @migrations[schema_name][table_name].keys.join("_"),
          migration: @migrations[schema_name][table_name].values.join("\n")
        }
      end
    end

    private

    def add_migration schema_name, table_name, migration_name, migration
      raise ExpectedSymbolError, "Expected schema_name to be a symbol, got #{schema_name}" unless schema_name.is_a?(Symbol)
      raise ExpectedSymbolError, "Expected table_name to be a symbol, got #{table_name}" unless schema_name.is_a?(Symbol)

      fixed_indentation_migration = fix_indentation migration
      @migrations[schema_name] ||= {}
      # if table_name is nil, then the migration is for the schema itself
      @migrations[schema_name][table_name || :schema] ||= {}
      @migrations[schema_name][table_name || :schema][migration_name] = fixed_indentation_migration
      # return the newly created migration
      fixed_indentation_migration
    end
  end
end
