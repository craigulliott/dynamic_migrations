module DynamicMigrations
  module Postgres
    class Generator
      module ConstraintComments
        class MissingDescriptionError < StandardError
        end

        # add a comment to a validation
        def set_validation_comment validation
          description = validation.description
          if description.nil?
            raise MissingDescriptionError
          end
          add_migration validation.table.schema.name, validation.table.name, :set_validation_comment, validation.name, <<~RUBY
            set_validation_comment :#{validation.table.name}, :#{validation.name}, <<~COMMENT
              #{indent description}
            COMMENT
          RUBY
        end

        # remove the comment from a validation
        def remove_validation_comment validation
          add_migration validation.table.schema.name, validation.table.name, :remove_validation_comment, validation.name, <<~RUBY
            remove_validation_comment :#{validation.table.name}, :#{validation.name}
          RUBY
        end

        # add a comment to a foreign_key_constraint
        def set_foreign_key_constraint_comment foreign_key_constraint
          description = foreign_key_constraint.description
          if description.nil?
            raise MissingDescriptionError
          end
          add_migration foreign_key_constraint.table.schema.name, foreign_key_constraint.table.name, :set_foreign_key_constraint_comment, foreign_key_constraint.name, <<~RUBY
            set_foreign_key_comment :#{foreign_key_constraint.table.name}, :#{foreign_key_constraint.name}, <<~COMMENT
              #{indent description}
            COMMENT
          RUBY
        end

        # remove the comment from a foreign_key_constraint
        def remove_foreign_key_constraint_comment foreign_key_constraint
          add_migration foreign_key_constraint.table.schema.name, foreign_key_constraint.table.name, :remove_foreign_key_constraint_comment, foreign_key_constraint.name, <<~RUBY
            remove_foreign_key_comment :#{foreign_key_constraint.table.name}, :#{foreign_key_constraint.name}
          RUBY
        end

        # add a comment to a unique_constraint
        def set_unique_constraint_comment unique_constraint
          description = unique_constraint.description
          if description.nil?
            raise MissingDescriptionError
          end
          add_migration unique_constraint.table.schema.name, unique_constraint.table.name, :set_unique_constraint_comment, unique_constraint.name, <<~RUBY
            set_unique_constraint_comment :#{unique_constraint.table.name}, :#{unique_constraint.name}, <<~COMMENT
              #{indent description}
            COMMENT
          RUBY
        end

        # remove the comment from a unique_constraint
        def remove_unique_constraint_comment unique_constraint
          add_migration unique_constraint.table.schema.name, unique_constraint.table.name, :remove_unique_constraint_comment, unique_constraint.name, <<~RUBY
            remove_unique_constraint_comment :#{unique_constraint.table.name}, :#{unique_constraint.name}
          RUBY
        end
      end
    end
  end
end
