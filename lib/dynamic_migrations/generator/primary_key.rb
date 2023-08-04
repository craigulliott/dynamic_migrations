module DynamicMigrations
  class Generator
    module PrimaryKey
      def add_primary_key primary_key
        # the migration accepts either a single column name or an array of column names
        # we use the appropriate syntax just to make the migration prettier and easier
        # to understand
        column_names = (primary_key.column_names.count == 1) ? ":#{primary_key.column_names.first}" : "[:#{primary_key.column_names.join(", :")}]"

        options = {
          name: ":#{primary_key.name}"
        }

        unless primary_key.description.nil?
          options[:comment] = "<<~COMMENT\n  #{primary_key.description}\nCOMMENT"
        end

        options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

        add_migration primary_key.table.schema.name, primary_key.table.name, "add_pk_#{primary_key.name}_on_#{primary_key.table.name}", <<~RUBY
          add_primary_key :#{primary_key.table.name}, #{column_names}, #{options_syntax}
        RUBY
      end

      def remove_primary_key primary_key
        add_migration primary_key.table.schema.name, primary_key.table.name, "remove_#{primary_key.name}_from_#{primary_key.table.name}", <<~RUBY
          remove_primary_key :#{primary_key.table.name}, :#{primary_key.name}
        RUBY
      end
    end
  end
end
