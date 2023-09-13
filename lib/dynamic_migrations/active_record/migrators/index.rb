module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Index
        # add a comment to the index
        # table name is not needed, but is included here for consistency with the other
        # rils migrations methods, and to make it easier to understand what table this
        # index is relate to
        def set_index_comment table_name, index_name, comment
          execute <<~SQL
            COMMENT ON INDEX #{index_name} IS #{quote comment};
          SQL
        end

        # remove a index comment
        # table name is not needed, but is included here for consistency with the other
        # rils migrations methods, and to make it easier to understand what table this
        # index is relate to
        def remove_index_comment table_name, index_name
          execute <<~SQL
            COMMENT ON INDEX #{index_name} IS NULL;
          SQL
        end
      end
    end
  end
end
