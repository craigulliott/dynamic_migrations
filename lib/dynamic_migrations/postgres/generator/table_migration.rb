module DynamicMigrations
  module Postgres
    class Generator
      class TableMigration < Migration
        # these sections are in order for which they will appear in a migration,
        # note that removals come before additions, and that the order here optomizes
        # for dependencies (i.e. columns have to be created before indexes are added and
        # triggers are removed before functions are dropped)
        add_structure_template [:remove_trigger_comment, :remove_trigger], "Remove Triggers"
        add_structure_template [:remove_validation, :remove_unique_constraint], "Remove Validations"
        add_structure_template [:remove_foreign_key], "Remove Foreign Keys"
        add_structure_template [:remove_primary_key], "Remove Primary Keys"
        add_structure_template [:remove_index, :remove_index_comment], "Remove Indexes"
        add_structure_template [:remove_column], "Remove Columns"
        add_structure_template [:drop_table], "Remove Tables"
        add_structure_template [:create_table], "Create Table"
        add_structure_template [:remove_table_comment, :set_table_comment], "Tables"
        add_structure_template [:add_column], "Additional Columns"
        add_structure_template [:change_column, :remove_column_comment, :set_column_comment], "Update Columns"
        add_structure_template [:add_primary_key], "Primary Key"
        add_structure_template [:add_index, :set_index_comment], "Indexes"
        add_structure_template [:add_foreign_key, :set_foreign_key_constraint_comment, :remove_foreign_key_constraint_comment], "Foreign Keys"
        add_structure_template [:add_validation, :add_unique_constraint, :set_validation_comment, :remove_validation_comment, :set_unique_constraint_comment, :remove_unique_constraint_comment], "Validations"
        add_structure_template [:create_function], "Functions"
        add_structure_template [:add_trigger, :set_trigger_comment], "Triggers"
        add_structure_template [:update_function, :set_function_comment], "Update Functions"

        def initialize schema_name, table_name
          raise MissingRequiredSchemaName unless schema_name
          raise MissingRequiredTableName unless table_name
          super
        end
      end
    end
  end
end
