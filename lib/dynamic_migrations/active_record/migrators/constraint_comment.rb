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
      end
    end
  end
end
