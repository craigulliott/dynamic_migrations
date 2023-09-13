module DynamicMigrations
  module ActiveRecord
    module Migrators
      module ForeignKeyConstraint
        class ForeignKeyOnDeleteOptionsError < StandardError
        end

        class UnexpectedReferentialActionError < StandardError
        end

        # because rails migrations don't support composite (multiple column) foreign keys
        # column_names and foreign_column_names can be a single column name or
        # an array of column names
        def add_foreign_key table_name, column_names, foreign_schema_name, foreign_table_name, foreign_column_names, name:, initially_deferred: false, deferrable: false, on_delete: :no_action, on_update: :no_action, comment: nil
          if initially_deferred == true && deferrable == false
            raise DeferrableOptionsError, "A constraint can only be initially deferred if it is also deferrable"
          end

          # convert single column names into arrays, this simplifies the logic below
          column_names = column_names.is_a?(Array) ? column_names : [column_names]
          foreign_column_names = foreign_column_names.is_a?(Array) ? foreign_column_names : [foreign_column_names]

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
                FOREIGN KEY (#{column_names.join(", ")})
                  REFERENCES  #{foreign_schema_name}.#{foreign_table_name} (#{foreign_column_names.join(", ")})
              ON DELETE #{referential_action_to_sql on_delete}
              ON UPDATE #{referential_action_to_sql on_update}
              #{deferrable_sql};
          SQL

          if comment.is_a? String
            set_foreign_key_comment table_name, name, comment
          end
        end

        def remove_foreign_key table_name, name
          execute <<~SQL
            ALTER TABLE #{table_name}
              DROP CONSTRAINT #{name};
          SQL
        end

        # add a comment to the foreign_key
        def set_foreign_key_comment table_name, foreign_key_name, comment
          execute <<~SQL
            COMMENT ON CONSTRAINT #{foreign_key_name} ON #{schema_name}.#{table_name} IS #{quote comment};
          SQL
        end

        # remove a foreign_key comment
        def remove_foreign_key_comment table_name, foreign_key_name
          execute <<~SQL
            COMMENT ON CONSTRAINT #{foreign_key_name} ON #{schema_name}.#{table_name} IS NULL;
          SQL
        end

        private

        def referential_action_to_sql referential_action
          case referential_action
          # Produce an error indicating that the deletion or update would create a
          # foreign key constraint violation. If the constraint is deferred, this
          # error will be produced at constraint check time if there still exist
          # any referencing rows. This is the default action.
          when :no_action
            "NO ACTION"

          # Produce an error indicating that the deletion or update would create a
          # foreign key constraint violation. This is the same as NO ACTION except
          # that the check is not deferrable.
          when :restrict
            "RESTRICT"

          # Delete any rows referencing the deleted row, or update the values of
          # the referencing column(s) to the new values of the referenced columns,
          # respectively.
          when :cascade
            "CASCADE"

          # Set all of the referencing columns, or a specified subset of the
          # referencing columns, to null.
          when :set_null
            "SET NULL"

          # Set all of the referencing columns, or a specified subset of the
          # referencing columns, to their default values.
          when :set_default
            "SET DEFAULT"

          else
            raise UnexpectedReferentialActionError, referential_action
          end
        end
      end
    end
  end
end
