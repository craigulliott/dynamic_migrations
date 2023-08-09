module DynamicMigrations
  module Postgres
    class Generator
      module Function
        def create_function function
          options = {
            name: ":#{function.name}"
          }
          unless function.description.nil?
            options[:comment] = "<<~COMMENT\n  #{function.description}\nCOMMENT"
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_migration function.schema.name, function.triggers.first&.table&.name, :create_function, function.name, <<~RUBY
            #{function.name}_definition = <<~SQL
              NEW.column = 0;
            SQL
            create_function :#{function.name}, #{function.name}_definition, #{options_syntax}
          RUBY
        end

        def update_function function
          options = {
            name: ":#{function.name}"
          }
          unless function.description.nil?
            options[:comment] = "<<~COMMENT\n  #{function.description}\nCOMMENT"
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_migration function.schema.name, function.triggers.first&.table&.name, :update_function, function.name, <<~RUBY
            #{function.name}_definition = <<~SQL
              NEW.column = 0;
            SQL
            update_function :#{function.name}, #{function.name}_definition, #{options_syntax}
          RUBY
        end

        def drop_function function
          add_migration function.schema.name, function.triggers.first&.table&.name, :drop_function, function.name, <<~RUBY
            drop_function :#{function.name}
          RUBY
        end

        # add a comment to a function
        def set_function_comment function
          add_migration function.schema.name, function.triggers.first&.table&.name, :set_function_comment, function.name, <<~RUBY
            set_function_comment :#{function.name}, <<~COMMENT
              #{function.description}
            COMMENT
          RUBY
        end

        # remove the comment from a function
        def remove_function_comment function
          add_migration function.schema.name, function.triggers.first&.table&.name, :remove_function_comment, function.name, <<~RUBY
            remove_function_comment :#{function.name}
          RUBY
        end
      end
    end
  end
end
