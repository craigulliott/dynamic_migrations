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

          # We only add the columns that are not enums from within the add_table block, this
          # is because columns that are enums require those enums to be created first and we
          # want to create those as seperate fragments which have the correct dependency metadata
          columns_without_enums = table.columns.reject(&:enum)
          columns_with_enums = table.columns.select(&:enum)

          fragments = []
          fragments << add_fragment(schema: table.schema,
            table: table,
            migration_method: :create_table,
            object: table,
            code_comment: code_comment,
            migration: <<~RUBY
              table_comment = <<~COMMENT
                #{indent table.description || ""}
              COMMENT
              create_table :#{table.name}, #{table_options table} do |t|
                #{indent table_columns(columns_without_enums)}
              end
            RUBY
          )

          # seperately add the columns that are enums (so dependency managment works correctly)
          fragments += columns_with_enums.map do |column|
            add_column column
          end

          # return all the fragments (we do this with all generators so e can more easily test the methods)
          fragments
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
            # skip creating the :id column as it is handled by the table_options
            # method, but add the comment if there is one
            if column.name == :id
              unless column.description.nil?
                set_column_comment column
              end
              next
            end
            # skip creating the :created_at and :updated_at column as it is handled
            # by the table_options method, but add the comments
            if column.name == :created_at || column.name == :updated_at
              unless column.description.nil?
                set_column_comment column
              end
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
            options[:comment] = <<~RUBY.strip
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

            lines << "t.column :#{column.name}, #{data_type}, #{options_syntax}"
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

            # if the primary key has a description, then add it seperately
            if table.primary_key.description
              set_primary_key_comment table.primary_key
            end

          end

          options << "comment: table_comment"

          options.join(", ")
        end
      end
    end
  end
end
