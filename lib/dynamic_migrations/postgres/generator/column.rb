module DynamicMigrations
  module Postgres
    class Generator
      module Column
        class NoColumnCommentError < StandardError
        end

        def add_column column
          if column.description.nil?
            raise NoColumnCommentError, "Refusing to generate add_column migration, no description was provided for `#{column.table.name}`.`#{column.table.schema.name}` column `#{column.name}`"
          end

          options = {}
          options[:null] = column.null

          unless column.default.nil?
            options[:default] = "\"#{column.default}\""
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_migration column.table.schema.name, column.table.name, :add_column, column.name, <<~RUBY
            add_column :#{column.table.name}, :#{column.name}, :#{column.data_type}, #{options_syntax}, comment: <<~COMMENT
              #{column.description}
            COMMENT
          RUBY
        end

        def remove_column column
          add_migration column.table.schema.name, column.table.name, :remove_column, column.name, <<~RUBY
            remove_column :#{column.table.name}, :#{column.name}
          RUBY
        end
      end
    end
  end
end
