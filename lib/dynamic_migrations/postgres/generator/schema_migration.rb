module DynamicMigrations
  module Postgres
    class Generator
      class SchemaMigration < Migration
        # these sections are in order for which they will appear in a migration,
        # note that removals come before additions, and that the order here optomizes
        # for dependencies (i.e. columns have to be created before indexes are added and
        # triggers are removed before functions are dropped)
        add_structure_template [:remove_function_comment, :drop_function], "Remove Functions"
        add_structure_template [:remove_enum_comment, :drop_enum], "Drop Enums"
        add_structure_template [:create_enum, :add_enum_values, :set_enum_comment], "Enums"
        add_structure_template [:create_function], "Functions"
        add_structure_template [:update_function, :set_function_comment], "Update Functions"

        def initialize schema_name
          raise MissingRequiredSchemaName unless schema_name
          super
        end
      end
    end
  end
end
