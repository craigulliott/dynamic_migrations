module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Column
        # add a comment to the column
        def set_column_comment table_name, column_name, comment
          execute <<~SQL
            COMMENT ON COLUMN #{schema_name}.#{table_name}.#{column_name} IS '#{quote comment}';
          SQL
        end

        # remove a column comment
        def remove_column_comment table_name, column_name
          execute <<~SQL
            COMMENT ON COLUMN #{schema_name}.#{table_name}.#{column_name} IS NULL;
          SQL
        end
      end
    end
  end
end
