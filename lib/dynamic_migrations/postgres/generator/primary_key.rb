module DynamicMigrations
  module Postgres
    class Generator
      module PrimaryKey
        def add_primary_key primary_key, code_comment = nil
          # the migration accepts either a single column name or an array of column names
          # we use the appropriate syntax just to make the migration prettier and easier
          # to understand
          column_names = (primary_key.column_names.count == 1) ? ":#{primary_key.column_names.first}" : "[:#{primary_key.column_names.join(", :")}]"

          options = {
            name: ":#{primary_key.name}"
          }

          unless primary_key.description.nil?
            options[:comment] = <<~RUBY
              <<~COMMENT
                #{indent primary_key.description}
              COMMENT
            RUBY
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_fragment schema: primary_key.table.schema,
            table: primary_key.table,
            migration_method: :add_primary_key,
            object: primary_key,
            code_comment: code_comment,
            migration: <<~RUBY
              add_primary_key :#{primary_key.table.name}, #{column_names}, #{options_syntax}
            RUBY
        end

        def remove_primary_key primary_key, code_comment = nil
          add_fragment schema: primary_key.table.schema,
            table: primary_key.table,
            migration_method: :remove_primary_key,
            object: primary_key,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_primary_key :#{primary_key.table.name}, :#{primary_key.name}
            RUBY
        end

        def recreate_primary_key original_primary_key, updated_primary_key
          # remove the original primary_key
          removal_fragment = remove_primary_key original_primary_key, <<~CODE_COMMENT
            Removing original primary key because it has changed (it is recreated below)
            Changes:
              #{indent original_primary_key.differences_descriptions(updated_primary_key).join("\n")}
          CODE_COMMENT

          # recrete the primary_key with the new options
          recreation_fragment = add_primary_key updated_primary_key, <<~CODE_COMMENT
            Recreating this primary key
          CODE_COMMENT

          # return the new fragments (the main reason to return them here is for the specs)
          [removal_fragment, recreation_fragment]
        end
      end
    end
  end
end
