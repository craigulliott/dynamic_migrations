module DynamicMigrations
  module Postgres
    class Generator
      module Table
        class NoTableCommentError < StandardError
        end

        class NoTableColumnCommentError < StandardError
        end

        def create_table table, code_comment = nil
          if table.description.nil?
            raise NoTableCommentError, "Refusing to generate create_table migration, no description was provided for `#{table.schema.name}`.`#{table.name}`"
          end

          add_fragment schema: table.schema,
            table: table,
            migration_method: :create_table,
            object: table,
            code_comment: code_comment,
            migration: <<~RUBY
              table_comment = <<~COMMENT
                #{indent table.description}
              COMMENT
              create_table :#{table.name}, #{table_options table} do |t|
                #{indent table_columns(table.columns)}
              end
            RUBY
        end

        def drop_table table, code_comment = nil
          add_fragment schema: table.schema,
            table: table,
            migration_method: :drop_table,
            object: table,
            code_comment: code_comment,
            migration: <<~RUBY
              drop_table :#{table.name}, force: true
            RUBY
        end

        # add a comment to a table
        def set_table_comment table, code_comment = nil
          description = table.description

          if description.nil?
            raise MissingDescriptionError, "Missing required description for table `#{table.schema.name}.#{table.name}`"
          end

          add_fragment schema: table.schema,
            table: table,
            migration_method: :set_table_comment,
            object: table,
            code_comment: code_comment,
            migration: <<~RUBY
              set_table_comment :#{table.name}, <<~COMMENT
                #{indent description}
              COMMENT
            RUBY
        end

        # remove the comment from a table
        def remove_table_comment table, code_comment = nil
          add_fragment schema: table.schema,
            table: table,
            migration_method: :remove_table_comment,
            object: table,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_table_comment :#{table.name}
            RUBY
        end

        private

        def table_columns columns
          lines = []
          timestamps = []
          columns.each do |column|
            # skip the :id, as it is handled by the table_options method
            next if column.name == :id
            # skip the :created_at and :updated_at as they are handled below
            if column.name == :created_at || column.name == :updated_at
              timestamps << column.name
              next
            end

            options = {}
            options[:null] = column.null

            if column.array?
              options[:array] = true
            end

            unless column.default.nil?
              options[:default] = "\"#{column.default}\""
            end

            if column.description.nil?
              raise NoTableColumnCommentError, "Refusing to generate create_table migration, no description was provided for `#{column.table.schema.name}`.`#{column.table.name}` column `#{column.name}`"
            end
            options[:comment] = <<~RUBY
              <<~COMMENT
                #{indent column.description}
              COMMENT
            RUBY

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

            lines << "t.column #{data_type}, :#{column.name}, #{options_syntax}"
          end

          if timestamps.any?
            lines << "t.timestamps :#{timestamps.join(", :")}"
          end

          lines.join("\n")
        end

        def table_options table
          options = []
          options << if table.has_column?(:id)
            "id: :#{table.column(:id).data_type}"
          else
            "id: false"
          end

          if table.has_primary_key?
            pk_column_names = table.primary_key.columns.map(&:name)
            # if there is only one primary key column and it is not called id, then
            # we define it here. If it is called :id then we don't need to define it
            if pk_column_names.count == 1 && pk_column_names.first != :id
              options << "primary_key: :#{pk_column_names.first}"
            elsif pk_column_names.count > 1
              options << "primary_key: [:#{pk_column_names.join(", :")}]"
            end
          end

          options << "comment: table_comment"

          options.join(", ")
        end
      end
    end
  end
end
