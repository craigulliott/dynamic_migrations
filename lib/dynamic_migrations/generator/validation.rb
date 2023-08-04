module DynamicMigrations
  class Generator
    module Validation
      def add_validation validation
        add_migration validation.table.schema.name, validation.table.name, "validate_#{validation.name}_on_#{validation.table.name}", <<~RUBY
          #{validation.name}_check_clause = <<~SQL
            #{validation.check_clause}
          SQL
          add_check_constraint :#{validation.table.name}, #{validation.name}_check_clause, name: :#{validation.name}, initially_deferred: #{validation.initially_deferred}, deferrable: #{validation.deferrable}
        RUBY
      end

      def remove_validation validation
        add_migration validation.table.schema.name, validation.table.name, "remove_#{validation.name}_from_#{validation.table.name}", <<~RUBY
          remove_check_constraint :#{validation.table.name}, :#{validation.name}
        RUBY
      end
    end
  end
end
