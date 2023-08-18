module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Function
        class FunctionDoesNotExistError < StandardError
        end

        class MissingFunctionBlockError < StandardError
        end

        # create a postgres function
        def create_function table_name, function_name, comment: nil, &block
          unless block
            raise MissingFunctionBlockError, "create_function requires a block"
          end
          # todo - remove this once steep/rbs can better handle blocks
          unless block.is_a? NilClass
            fn_sql = block.call.strip
          end

          # schema_name was not provided to this method, it comes from the migration class
          execute <<~SQL
            CREATE FUNCTION #{schema_name}.#{function_name}() returns trigger language plpgsql AS
            $$#{fn_sql}$$;
          SQL

          if comment.is_a? String
            set_function_comment function_name, comment
          end
        end

        # update a postgres function
        def update_function table_name, function_name, comment: nil, &block
          unless block
            raise MissingFunctionBlockError, "create_function requires a block"
          end
          # todo - remove this once steep/rbs can better handle blocks
          unless block.is_a? NilClass
            fn_sql = block.call.strip
          end

          # schema_name was not provided to this method, it comes from the migration class
          # assert it already exists
          exists_result = execute <<~SQL
            SELECT TRUE as exists
            FROM pg_proc p
            INNER JOIN pg_namespace p_n
              ON p_n.oid = p.pronamespace
            WHERE
              p.proname = #{function_name}
              AND p_n.nspname = #{schema_name}
              -- arguments (defaulting to none for now)
              AND pg_get_function_identity_arguments(p.oid) = ''
          SQL

          unless exists_result.to_a.first["exists"]
            raise FunctionDoesNotExistError, "Can not update Function. Function #{schema_name}.#{function_name} does not exist."
          end

          # create or replace will update the function
          execute <<~SQL
            CREATE OR REPLACE FUNCTION #{schema_name}.#{function_name}() returns trigger language plpgsql AS
            $$#{fn_sql}$$;
          SQL

          if comment.is_a? String
            set_function_comment function_name, comment
          end
        end

        # remove a function from the schema
        def drop_function function_name
          execute <<~SQL
            DROP FUNCTION #{schema_name}.#{function_name}();
          SQL
        end

        # add a comment to a function
        def set_function_comment function_name, comment
          execute <<~SQL
            COMMENT ON FUNCTION #{schema_name}.#{function_name} IS '#{quote comment}';
          SQL
        end

        # remove the comment from a function
        def remove_function_comment function_name
          execute <<~SQL
            COMMENT ON FUNCTION #{schema_name}.#{function_name} IS null;
          SQL
        end
      end
    end
  end
end
