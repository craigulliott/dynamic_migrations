module DynamicMigrations
  module Postgres
    class Generator
      module ForeignKeyConstraint
        def add_foreign_key_constraint foreign_key_constraint
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
            options[:comment] = "<<~COMMENT\n  #{foreign_key_constraint.description}\nCOMMENT"
          end
          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_migration foreign_key_constraint.table.schema.name, foreign_key_constraint.table.name, :add_foreign_key, foreign_key_constraint.name, <<~RUBY
            add_foreign_key :#{foreign_key_constraint.table.name}, #{column_names}, :#{foreign_key_constraint.foreign_table.name}, #{foreign_column_names}, #{options_syntax}
          RUBY
        end

        def remove_foreign_key_constraint foreign_key_constraint
          add_migration foreign_key_constraint.table.schema.name, foreign_key_constraint.table.name, :remove_foreign_key, foreign_key_constraint.name, <<~RUBY
            remove_foreign_key :#{foreign_key_constraint.table.name}, :#{foreign_key_constraint.name}
          RUBY
        end
      end
    end
  end
end
