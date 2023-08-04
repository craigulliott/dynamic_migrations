module DynamicMigrations
  class Generator
    module Table
      class NoTableCommentError < StandardError
      end

      class NoTableColumnCommentError < StandardError
      end

      def create_table table
        if table.description.nil?
          raise NoTableCommentError, "Refusing to generate create_table migration, no description was provided for `#{table.name}`.`#{table.schema.name}`"
        end

        add_migration table.schema.name, table.name, "create_#{table.name}", <<~RUBY
          table_comment = <<~COMMENT
            #{table.description}
          COMMENT
          create_table :#{table.name}, #{table_options table} do |t|
            #{table_columns(table.columns)}
          end
        RUBY
      end

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

          line = "t.#{column.data_type} :#{column.name}, null: #{column.null}"

          unless column.default.nil?
            line << ", default: \"#{column.default}\""
          end

          if column.description.nil?
            raise NoTableColumnCommentError, "Refusing to generate create_table migration, no description was provided for `#{column.table.name}`.`#{column.table.schema.name}` column `#{column.name}`"
          end
          line << ", comment: <<~COMMENT\n  #{column.description}\nCOMMENT"

          lines << line
        end

        if timestamps.any?
          lines << "t.timestamps :#{timestamps.join(", :")}"
        end

        lines.join("\n")
      end

      def drop_table table
        add_migration table.schema.name, table.name, "create_#{table.name}", <<~RUBY
          drop_table :#{table.name}, force: true
        RUBY
      end

      private

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
