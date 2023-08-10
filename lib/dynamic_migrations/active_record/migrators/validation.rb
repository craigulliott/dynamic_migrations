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
            set_constraint_comment table_name, name, comment
          end
        end

        warn "not tested"
        def remove_validation table_name, name
          remove_check_constraint table_name, name
        end

        warn "not tested"
        def change_validation table_name, name:, initially_deferred: false, deferrable: false, comment: nil, &block
          remove_validation table_name, name
          create_validation table_name, name:, initially_deferred:, deferrable:, comment:, &block
        end
      end
    end
  end
end
