module DynamicMigrations
  module ActiveRecord
    module Migrators
      module TableComment
        # add a comment to the table
        def set_table_comment table_name, comment
          execute <<~SQL
            COMMENT ON TABLE #{schema_name}.#{table_name} IS '#{quote comment}';
          SQL
        end

        # remove a table comment
        def remove_table_comment table_name
          execute <<~SQL
            COMMENT ON TABLE #{schema_name}.#{table_name} IS NULL;
          SQL
        end
      end
    end
  end
end
