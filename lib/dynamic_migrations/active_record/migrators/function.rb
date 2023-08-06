module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Function
        # create a postgres function
        warn "not tested"
        def create_function table_name, function_name, fn_sql, comment: nil
          # schema_name was not provided to this method, it comes from the migration class
          execute <<~SQL
            CREATE FUNCTION #{schema_name}.#{function_name}() returns trigger language plpgsql AS
            $$BEGIN #{fn_sql.strip};
            RETURN NEW;
            END$$;
          SQL

          unless comment.nil?
            add_function_comment name, comment
          end
        end

        def add_function_comment function_name, comment
          execute <<~SQL
            COMMENT ON FUNCTION #{function_name} IS '#{connection.quote comment}';
          SQL
        end
      end
    end
  end
end
