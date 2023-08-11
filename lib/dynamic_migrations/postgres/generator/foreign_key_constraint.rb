module DynamicMigrations
  module Postgres
    class Generator
      module ForeignKeyConstraint
        def add_foreign_key_constraint foreign_key_constraint, code_comment = nil
          # the migration accepts either a single column name or an array of column names
          # we use the appropriate syntax just to make the migration prettier and easier
          # to understand
          p_c_names = foreign_key_constraint.column_names
          column_names = (p_c_names.count == 1) ? ":#{p_c_names.first}" : "[:#{p_c_names.join(", :")}]"

          f_c_names = foreign_key_constraint.foreign_column_names
          foreign_column_names = (f_c_names.count == 1) ? ":#{f_c_names.first}" : "[:#{f_c_names.join(", :")}]"

          options = {
            name: ":#{foreign_key_constraint.name}",
            initially_deferred: foreign_key_constraint.initially_deferred,
            deferrable: foreign_key_constraint.deferrable,
            on_delete: ":#{foreign_key_constraint.on_delete}",
            on_update: ":#{foreign_key_constraint.on_update}"
          }
          unless foreign_key_constraint.description.nil?
            options[:comment] = <<~RUBY
              <<~COMMENT
                #{indent foreign_key_constraint.description}
              COMMENT
            RUBY
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_migration foreign_key_constraint.table.schema.name, foreign_key_constraint.table.name, :add_foreign_key, foreign_key_constraint.name, code_comment, <<~RUBY
            add_foreign_key :#{foreign_key_constraint.table.name}, #{column_names}, :#{foreign_key_constraint.foreign_table.name}, #{foreign_column_names}, #{options_syntax}
          RUBY
        end

        def remove_foreign_key_constraint foreign_key_constraint, code_comment = nil
          add_migration foreign_key_constraint.table.schema.name, foreign_key_constraint.table.name, :remove_foreign_key, foreign_key_constraint.name, code_comment, <<~RUBY
            remove_foreign_key :#{foreign_key_constraint.table.name}, :#{foreign_key_constraint.name}
          RUBY
        end

        def recreate_foreign_key_constraint original_foreign_key_constraint, updated_foreign_key_constraint
          # remove the original foreign_key_constraint
          removal_fragment = remove_foreign_key_constraint original_foreign_key_constraint, <<~CODE_COMMENT
            Removing original foreign key constraint because it has changed (it is recreated below)
            Changes:
              #{indent original_foreign_key_constraint.differences_descriptions(updated_foreign_key_constraint).join("\n")}
          CODE_COMMENT

          # recrete the foreign_key_constraint with the new options
          recreation_fragment = add_foreign_key_constraint updated_foreign_key_constraint, <<~CODE_COMMENT
            Recreating this foreign key constraint
          CODE_COMMENT

          # return the new fragments (the main reason to return them here is for the specs)
          [removal_fragment, recreation_fragment]
        end

        # add a comment to a foreign_key_constraint
        def set_foreign_key_constraint_comment foreign_key_constraint, code_comment = nil
          description = foreign_key_constraint.description

          if description.nil?
            raise MissingDescriptionError
          end

          add_migration foreign_key_constraint.table.schema.name, foreign_key_constraint.table.name, :set_foreign_key_constraint_comment, foreign_key_constraint.name, code_comment, <<~RUBY
            set_foreign_key_comment :#{foreign_key_constraint.table.name}, :#{foreign_key_constraint.name}, <<~COMMENT
              #{indent description}
            COMMENT
          RUBY
        end

        # remove the comment from a foreign_key_constraint
        def remove_foreign_key_constraint_comment foreign_key_constraint, code_comment = nil
          add_migration foreign_key_constraint.table.schema.name, foreign_key_constraint.table.name, :remove_foreign_key_constraint_comment, foreign_key_constraint.name, code_comment, <<~RUBY
            remove_foreign_key_comment :#{foreign_key_constraint.table.name}, :#{foreign_key_constraint.name}
          RUBY
        end
      end
    end
  end
end
