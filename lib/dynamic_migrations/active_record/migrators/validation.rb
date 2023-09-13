module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Validation
        # this exists because because the standard rails migration does not support deffered constraints
        def add_validation table_name, name:, initially_deferred: false, deferrable: false, comment: nil, &block
          unless block
            raise MissingFunctionBlockError, "create_function requires a block"
          end
          # todo - remove this once steep/rbs can better handle blocks
          unless block.is_a? NilClass
            sql = block.call.strip
          end

          if initially_deferred == true && deferrable == false
            raise DeferrableOptionsError, "A constraint can only be initially deferred if it is also deferrable"
          end

          # allow it to be deferred, and defer it by default
          deferrable_sql = if initially_deferred
            "DEFERRABLE INITIALLY DEFERRED"

          # allow it to be deferred, but do not deferr by default
          elsif deferrable
            "DEFERRABLE INITIALLY IMMEDIATE"

          # it can not be deferred (this is the default)
          else
            "NOT DEFERRABLE"
          end

          execute <<~SQL
            ALTER TABLE #{table_name}
              ADD CONSTRAINT #{name}
                CHECK (#{sql})
                #{deferrable_sql};
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
