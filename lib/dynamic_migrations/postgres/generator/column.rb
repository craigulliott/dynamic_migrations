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

          if column.array?
            options[:array] = true
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          data_type = column.data_type
          if column.array?
            data_type = "\"#{data_type}\""
          end

          add_migration column.table.schema.name, column.table.name, :add_column, column.name, <<~RUBY
            add_column :#{column.table.name}, :#{column.name}, :#{data_type}, #{options_syntax}, comment: <<~COMMENT
              #{indent column.description}
            COMMENT
          RUBY
        end

        def change_column column
          options = {}
          options[:null] = column.null

          unless column.default.nil?
            options[:default] = "\"#{column.default}\""
          end

          if column.array?
            options[:array] = true
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          data_type = column.data_type
          if column.array?
            data_type = ":\"#{data_type}\""
          end

          add_migration column.table.schema.name, column.table.name, :change_column, column.name, <<~RUBY
            change_column :#{column.table.name}, :#{column.name}, :#{data_type}, #{options_syntax}
          RUBY
        end

        def remove_column column
          add_migration column.table.schema.name, column.table.name, :remove_column, column.name, <<~RUBY
            remove_column :#{column.table.name}, :#{column.name}
          RUBY
        end

        # add a comment to a column
        def set_column_comment column
          add_migration column.table.schema.name, column.table.name, :set_column_comment, column.name, <<~RUBY
            set_column_comment :#{column.table.name}, :#{column.name}, <<~COMMENT
              #{indent column.description}
            COMMENT
          RUBY
        end

        # remove the comment from a column
        def remove_column_comment column
          add_migration column.table.schema.name, column.table.name, :remove_column_comment, column.name, <<~RUBY
            remove_column_comment :#{column.table.name}, :#{column.name}
          RUBY
        end
      end
    end
  end
end
