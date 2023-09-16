module DynamicMigrations
  module ActiveRecord
    module Migrators
      module PrimaryKey
        # add a comment to the primary_key
        def set_primary_key_comment table_name, primary_key_name, comment
          execute <<~SQL
            COMMENT ON CONSTRAINT #{primary_key_name} ON #{schema_name}.#{table_name} IS #{quote comment};
          SQL
        end

        # remove a primary_key comment
        def remove_primary_key_comment table_name, primary_key_name
          execute <<~SQL
            COMMENT ON CONSTRAINT #{primary_key_name} ON #{schema_name}.#{table_name} IS NULL;
          SQL
        end
      end
    end
  end
end
