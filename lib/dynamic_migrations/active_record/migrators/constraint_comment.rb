module DynamicMigrations
  module ActiveRecord
    module Migrators
      module ConstraintComment
        # add a comment to the constraint
        def add_constraint_comment table_name, constraint_name, comment
          execute <<~SQL
            COMMENT ON CONSTRAINT #{constraint_name} ON #{table_name} IS '#{connection.quote comment}';
          SQL
        end
      end
    end
  end
end
