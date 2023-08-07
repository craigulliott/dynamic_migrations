module DynamicMigrations
  module ActiveRecord
    module Migrators
      module CheckConstraint
        # this exists because because the standard rails migration does not support deffered constraints
        def add_check_constraint table_name, sql, name:, initially_deferred: false, deferrable: false, comment: nil
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
      end
    end
  end
end
