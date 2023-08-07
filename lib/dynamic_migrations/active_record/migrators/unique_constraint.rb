module DynamicMigrations
  module ActiveRecord
    module Migrators
      module UniqueConstraint
        # because rails migrations don't support composite (multiple column) foreign keys
        # column_names can be a single column name or an array of column names
        def add_unique_constraint table_name, column_names, name:, deferrable: false, initially_deferred: false, comment: nil
          if initially_deferred == true && deferrable == false
            raise DeferrableOptionsError, "A constraint can only be initially deferred if it is also deferrable"
          end

          # convert single column names into arrays, this simplifies the logic below
          column_names = column_names.is_a?(Array) ? column_names : [column_names]

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
                UNIQUE (#{column_names.join(", ")})
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
