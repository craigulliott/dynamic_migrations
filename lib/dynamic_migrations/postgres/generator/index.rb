module DynamicMigrations
  module Postgres
    class Generator
      module Index
        def add_index index, code_comment = nil
          # the migration accepts either a single column name or an array of column names
          # we use the appropriate syntax just to make the migration prettier and easier
          # to understand
          column_names = (index.column_names.count == 1) ? ":#{index.column_names.first}" : "[:#{index.column_names.join(", :")}]"

          options = {
            name: ":#{index.name}",
            unique: index.unique,
            using: ":#{index.type}",
            # todo: support custom sorting, it requires refactoring the index class because the ordering is actually on a column by column basis, not the index itself
            sort: ":#{index.order}"
          }

          # :first is the default when :desc is specified, :last is the default when :asc is specified
          if (index.order == :desc && index.nulls_position == :last) || (index.order == :asc && index.nulls_position == :first)
            # todo: support nulls_position, it requires writing our own migrator because rails does not provide this option
            raise "custom nulls_position is not currently supported"
          end

          unless index.where.nil?
            options[:where] = "\"#{index.where}\""
          end

          unless index.description.nil?
            options[:comment] = <<~RUBY
              <<~COMMENT
                #{indent index.description}
              COMMENT
            RUBY
          end

          where_sql = ""
          unless index.where.nil?
            options[:where] = "#{index.name}_where_sql"
            where_sql = <<~RUBY
              #{index.name}_where_sql = <<~SQL
                #{indent index.where}
              SQL
            RUBY
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_fragment schema: index.table.schema,
            table: index.table,
            migration_method: :add_index,
            object: index,
            code_comment: code_comment,
            migration: where_sql + <<~RUBY
              add_index :#{index.table.name}, #{column_names}, #{options_syntax}
            RUBY
        end

        def remove_index index, code_comment = nil
          add_fragment schema: index.table.schema,
            table: index.table,
            migration_method: :remove_index,
            object: index,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_index :#{index.table.name}, :#{index.name}
            RUBY
        end

        def recreate_index original_index, updated_index
          # remove the original index
          removal_fragment = remove_index original_index, <<~CODE_COMMENT
            Removing original index because it has changed (it is recreated below)
            Changes:
              #{indent original_index.differences_descriptions(updated_index).join("\n")}
          CODE_COMMENT

          # recrete the index with the new options
          recreation_fragment = add_index updated_index, <<~CODE_COMMENT
            Recreating this index
          CODE_COMMENT

          # return the new fragments (the main reason to return them here is for the specs)
          [removal_fragment, recreation_fragment]
        end

        # add a comment to a index
        def set_index_comment index, code_comment = nil
          description = index.description

          if description.nil?
            raise MissingDescriptionError, "Missing required description for index `#{index.name}` in table `#{index.table.schema.name}.#{index.table.name}`"
          end

          add_fragment schema: index.table.schema,
            table: index.table,
            migration_method: :set_index_comment,
            object: index,
            code_comment: code_comment,
            migration: <<~RUBY
              set_index_comment :#{index.table.name}, :#{index.name}, <<~COMMENT
                #{indent description}
              COMMENT
            RUBY
        end

        # remove the comment from a index
        def remove_index_comment index, code_comment = nil
          add_fragment schema: index.table.schema,
            table: index.table,
            migration_method: :remove_index_comment,
            object: index,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_index_comment :#{index.table.name}, :#{index.name}
            RUBY
        end
      end
    end
  end
end
