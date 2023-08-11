module DynamicMigrations
  module Postgres
    class Generator
      module UniqueConstraint
        def add_unique_constraint unique_constraint, code_comment = nil
          # the migration accepts either a single column name or an array of column names
          # we use the appropriate syntax just to make the migration prettier and easier
          # to understand
          column_names = (unique_constraint.column_names.count == 1) ? ":#{unique_constraint.column_names.first}" : "[:#{unique_constraint.column_names.join(", :")}]"

          options = {
            name: ":#{unique_constraint.name}",
            deferrable: unique_constraint.deferrable,
            initially_deferred: unique_constraint.initially_deferred
          }

          unless unique_constraint.description.nil?
            options[:comment] = <<~RUBY
              <<~COMMENT
                #{indent unique_constraint.description}
              COMMENT
            RUBY
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_migration unique_constraint.table.schema.name, unique_constraint.table.name, :add_unique_constraint, unique_constraint.name, code_comment, <<~RUBY
            add_unique_constraint :#{unique_constraint.table.name}, #{column_names}, #{options_syntax}
          RUBY
        end

        def remove_unique_constraint unique_constraint, code_comment = nil
          add_migration unique_constraint.table.schema.name, unique_constraint.table.name, :remove_unique_constraint, unique_constraint.name, code_comment, <<~RUBY
            remove_unique_constraint :#{unique_constraint.table.name}, :#{unique_constraint.name}
          RUBY
        end

        def recreate_unique_constraint original_unique_constraint, updated_unique_constraint
          # remove the original unique_constraint
          removal_fragment = remove_unique_constraint original_unique_constraint, <<~CODE_COMMENT
            Removing original unique constraint because it has changed (it is recreated below)
            Changes:
              #{indent original_unique_constraint.differences_descriptions(updated_unique_constraint).join("\n")}
          CODE_COMMENT

          # recrete the unique_constraint with the new options
          recreation_fragment = add_unique_constraint updated_unique_constraint, <<~CODE_COMMENT
            Recreating this unique constraint
          CODE_COMMENT

          # return the new fragments (the main reason to return them here is for the specs)
          [removal_fragment, recreation_fragment]
        end

        # add a comment to a unique_constraint
        def set_unique_constraint_comment unique_constraint, code_comment = nil
          description = unique_constraint.description

          if description.nil?
            raise MissingDescriptionError
          end

          add_migration unique_constraint.table.schema.name, unique_constraint.table.name, :set_unique_constraint_comment, unique_constraint.name, code_comment, <<~RUBY
            set_unique_constraint_comment :#{unique_constraint.table.name}, :#{unique_constraint.name}, <<~COMMENT
              #{indent description}
            COMMENT
          RUBY
        end

        # remove the comment from a unique_constraint
        def remove_unique_constraint_comment unique_constraint, code_comment = nil
          add_migration unique_constraint.table.schema.name, unique_constraint.table.name, :remove_unique_constraint_comment, unique_constraint.name, code_comment, <<~RUBY
            remove_unique_constraint_comment :#{unique_constraint.table.name}, :#{unique_constraint.name}
          RUBY
        end
      end
    end
  end
end
