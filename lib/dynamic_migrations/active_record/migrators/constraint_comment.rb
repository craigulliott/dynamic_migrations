module DynamicMigrations
  module ActiveRecord
    module Migrators
      module ConstraintComment
        # add a comment to the constraint
        def set_constraint_comment table_name, constraint_name, comment
          execute <<~SQL
            COMMENT ON CONSTRAINT #{constraint_name} ON #{schema_name}.#{table_name} IS '#{quote comment}';
          SQL
        end

        # remove a constraint comment
        def remove_constraint_comment table_name, constraint_name
          execute <<~SQL
            COMMENT ON CONSTRAINT #{constraint_name} ON #{schema_name}.#{table_name} IS NULL;
          SQL
        end

        # syntatic sugar for adding a comment to other kinds of constraints
        alias_method :set_validation_comment, :set_constraint_comment
        alias_method :set_foreign_key_comment, :set_constraint_comment
        alias_method :set_unique_constraint_comment, :set_constraint_comment

        alias_method :remove_validation_comment, :remove_constraint_comment
        alias_method :remove_foreign_key_comment, :remove_constraint_comment
        alias_method :remove_unique_constraint_comment, :remove_constraint_comment
      end
    end
  end
end
