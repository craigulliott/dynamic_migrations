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
            set_unique_constraint_comment table_name, name, comment
          end
        end

        def remove_unique_constraint table_name, name
          execute <<~SQL
            ALTER TABLE #{table_name}
              DROP CONSTRAINT #{name};
          SQL
        end

        # add a comment to the unique_constraint
        def set_unique_constraint_comment table_name, unique_constraint_name, comment
          execute <<~SQL
            COMMENT ON CONSTRAINT #{unique_constraint_name} ON #{schema_name}.#{table_name} IS '#{quote comment}';
          SQL
        end

        # remove a unique_constraint comment
        def remove_unique_constraint_comment table_name, unique_constraint_name
          execute <<~SQL
            COMMENT ON CONSTRAINT #{unique_constraint_name} ON #{schema_name}.#{table_name} IS NULL;
          SQL
        end
      end
    end
  end
end
