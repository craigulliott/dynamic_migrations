module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Validation
        # this exists because because the standard rails migration does not support deffered constraints
        def add_validation table_name, name:, comment: nil, &block
          unless block
            raise MissingFunctionBlockError, "create_function requires a block"
          end
          # todo - remove this once steep/rbs can better handle blocks
          unless block.is_a? NilClass
            sql = block.call.strip
          end

          execute <<~SQL
            ALTER TABLE #{table_name}
              ADD CONSTRAINT #{name}
                CHECK (#{sql});
          SQL

          if comment.is_a? String
            set_validation_comment table_name, name, comment
          end
        end

        def remove_validation table_name, name
          execute <<~SQL
            ALTER TABLE #{table_name}
              DROP CONSTRAINT #{name};
          SQL
        end

        # add a comment to the validation
        def set_validation_comment table_name, validation_name, comment
          execute <<~SQL
            COMMENT ON CONSTRAINT #{validation_name} ON #{schema_name}.#{table_name} IS #{quote comment};
          SQL
        end

        # remove a validation comment
        def remove_validation_comment table_name, validation_name
          execute <<~SQL
            COMMENT ON CONSTRAINT #{validation_name} ON #{schema_name}.#{table_name} IS NULL;
          SQL
        end
      end
    end
  end
end
