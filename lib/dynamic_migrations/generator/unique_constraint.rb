module DynamicMigrations
  class Generator
    module UniqueConstraint
      def add_unique_constraint unique_constraint
        # the migration accepts either a single column name or an array of column names
        # we use the appropriate syntax just to make the migration prettier and easier
        # to understand
        column_names = (unique_constraint.column_names.count == 1) ? ":#{unique_constraint.column_names.first}" : "[:#{unique_constraint.column_names.join(", :")}]"

        options = {
          name: ":#{unique_constraint.name}",
          index_type: ":#{unique_constraint.index_type}",
          deferrable: unique_constraint.deferrable,
          initially_deferred: unique_constraint.initially_deferred
        }

        unless unique_constraint.description.nil?
          options[:comment] = "<<~COMMENT\n  #{unique_constraint.description}\nCOMMENT"
        end

        options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

        add_migration unique_constraint.table.schema.name, unique_constraint.table.name, "add_unique_constraint_#{unique_constraint.name}_on_#{unique_constraint.table.name}", <<~RUBY
          add_unique_constraint :#{unique_constraint.table.name}, #{column_names}, #{options_syntax}
        RUBY
      end

      def remove_unique_constraint unique_constraint
        add_migration unique_constraint.table.schema.name, unique_constraint.table.name, "remove_#{unique_constraint.name}_from_#{unique_constraint.table.name}", <<~RUBY
          remove_unique_constraint :#{unique_constraint.table.name}, :#{unique_constraint.name}
        RUBY
      end
    end
  end
end