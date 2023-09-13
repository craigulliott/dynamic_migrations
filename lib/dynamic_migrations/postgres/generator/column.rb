module DynamicMigrations
  module Postgres
    class Generator
      module Column
        class NoColumnCommentError < StandardError
        end

        def add_column column, code_comment = nil
          if column.description.nil?
            raise NoColumnCommentError, "Refusing to generate add_column migration, no description was provided for `#{column.table.schema.name}`.`#{column.table.name}` column `#{column.name}`"
          end

          options = {}
          options[:null] = column.null

          unless column.default.nil?
            options[:default] = "\"#{column.default}\""
          end

          if column.array?
            options[:array] = true
          end

          # comment has to be last
          if column.description
            options[:comment] = <<~RUBY
              <<~COMMENT
                #{indent column.description}
              COMMENT
            RUBY
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          data_type = column.data_type.to_s
          # if it's an array, then we need to remove the [] from the end
          if column.array?
            data_type = data_type.sub(/\[\]\z/, "")
          end
          # if its a custom type (has special characters) then we need to quote it
          # otherwise, present it as a symbol
          data_type = if data_type.match?(/\A\w+\z/)
            ":#{data_type}"
          else
            "\"#{data_type}\""
          end

          add_fragment schema: column.table.schema,
            table: column.table,
            migration_method: :add_column,
            object: column,
            code_comment: code_comment,
            migration: <<~RUBY
              add_column :#{column.table.name}, :#{column.name}, #{data_type}, #{options_syntax}
            RUBY
        end

        def change_column column, code_comment = nil
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

          add_fragment schema: column.table.schema,
            table: column.table,
            migration_method: :change_column,
            object: column,
            code_comment: code_comment,
            migration: <<~RUBY
              change_column :#{column.table.name}, :#{column.name}, :#{data_type}, #{options_syntax}
            RUBY
        end

        def remove_column column, code_comment = nil
          add_fragment schema: column.table.schema,
            table: column.table,
            migration_method: :remove_column,
            object: column,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_column :#{column.table.name}, :#{column.name}
            RUBY
        end

        # add a comment to a column
        def set_column_comment column, code_comment = nil
          description = column.description

          if description.nil?
            raise MissingDescriptionError, "Missing required description for column `#{column.name}` in table `#{column.table.schema.name}.#{column.table.name}`"
          end

          add_fragment schema: column.table.schema,
            table: column.table,
            migration_method: :set_column_comment,
            object: column,
            code_comment: code_comment,
            migration: <<~RUBY
              set_column_comment :#{column.table.name}, :#{column.name}, <<~COMMENT
                #{indent description}
              COMMENT
            RUBY
        end

        # remove the comment from a column
        def remove_column_comment column, code_comment = nil
          add_fragment schema: column.table.schema,
            table: column.table,
            migration_method: :remove_column_comment,
            object: column,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_column_comment :#{column.table.name}, :#{column.name}
            RUBY
        end
      end
    end
  end
end
