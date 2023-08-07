module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Function
        # create a postgres function
        def create_function table_name, function_name, fn_sql, comment: nil
          # schema_name was not provided to this method, it comes from the migration class
          execute <<~SQL
            CREATE FUNCTION #{schema_name}.#{function_name}() returns trigger language plpgsql AS
            $$BEGIN #{fn_sql.strip};
            RETURN NEW;
            END$$;
          SQL

          if comment.is_a? String
            set_function_comment function_name, comment
          end
        end

        def drop_function function_name
          execute <<~SQL
            DROP FUNCTION #{schema_name}.#{function_name}();
          SQL
        end

        def set_function_comment function_name, comment
          execute <<~SQL
            COMMENT ON FUNCTION #{schema_name}.#{function_name} IS '#{quote comment}';
          SQL
        end

        def remove_function_comment function_name
          execute <<~SQL
            COMMENT ON FUNCTION #{schema_name}.#{function_name} IS null;
          SQL
        end
      end
    end
  end
end
