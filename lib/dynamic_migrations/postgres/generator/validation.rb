module DynamicMigrations
  module Postgres
    class Generator
      module Validation
        def add_validation validation, update = false
          options = {
            name: ":#{validation.name}",
            deferrable: validation.deferrable,
            initially_deferred: validation.initially_deferred
          }

          if validation.description.nil?
            comment_sql = ""
          else
            comment_sql = <<~RUBY
              #{validation.name}_comment = <<~COMMENT
                #{indent validation.description || ""}
              COMMENT
            RUBY
            options[:comment] = "#{validation.name}_comment"
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          validation_sql = validation.check_clause.strip
          # ensure that the validation ends with a semicolon
          unless validation_sql.end_with? ";"
            validation_sql << ";"
          end

          method_name = update ? :change_validation : :add_validation

          add_migration validation.table.schema.name, validation.table.name, :add_validation, validation.name, (comment_sql + <<~RUBY)
            #{method_name} :#{validation.table.name}, #{options_syntax} do
              <<~SQL
                #{indent validation_sql}
              SQL
            end
          RUBY
        end

        warn "not tested"
        def remove_validation validation
          add_migration validation.table.schema.name, validation.table.name, :remove_validation, validation.name, <<~RUBY
            remove_validation :#{validation.table.name}, :#{validation.name}
          RUBY
        end

        warn "not tested"
        def change_validation validation
          add_validation validation, true
        end
      end
    end
  end
end
