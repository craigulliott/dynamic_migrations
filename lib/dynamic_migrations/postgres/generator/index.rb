module DynamicMigrations
  module Postgres
    class Generator
      module Index
        def add_index index
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

          add_migration index.table.schema.name, index.table.name, :add_index, index.name, (where_sql + <<~RUBY)
            add_index :#{index.table.name}, #{column_names}, #{options_syntax}
          RUBY
        end

        def remove_index index
          add_migration index.table.schema.name, index.table.name, :remove_index, index.name, <<~RUBY
            remove_index :#{index.table.name}, :#{index.name}
          RUBY
        end
      end
    end
  end
end
