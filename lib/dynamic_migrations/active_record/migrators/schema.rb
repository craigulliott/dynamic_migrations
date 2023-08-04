module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Schema
        def create_schema schema_name
          execute <<~SQL
            CREATE SCHEMA #{schema_name};
          SQL
        end

        def drop_schema schema_name
          execute <<~SQL
            DROP SCHEMA #{schema_name};
          SQL
        end
      end
    end
  end
end
