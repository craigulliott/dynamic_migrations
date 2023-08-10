module DynamicMigrations
  module Postgres
    class Generator
      module Function
        def create_function function
          options = {}

          if function.description.nil?
            comment_sql = ""
          else
            comment_sql = <<~RUBY
              #{function.name}_comment = <<~COMMENT
                #{indent function.description || ""}
              COMMENT
            RUBY
            options[:comment] = "#{function.name}_comment"
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")
          optional_options_syntax = (options_syntax == "") ? "" : ", #{options_syntax}"

          fn_sql = function.definition.strip
          # ensure that the function ends with a semicolon
          unless fn_sql.end_with? ";"
            fn_sql << ";"
          end

          add_migration function.schema.name, function.triggers.first&.table&.name, :create_function, function.name, (comment_sql + <<~RUBY)
            create_function :#{function.name}#{optional_options_syntax} do
              <<~SQL
                #{indent fn_sql}
              SQL
            end
          RUBY
        end

        def update_function function
          fn_sql = function.definition.strip
          # ensure that the function ends with a semicolon
          unless fn_sql.end_with? ";"
            fn_sql << ";"
          end

          add_migration function.schema.name, function.triggers.first&.table&.name, :update_function, function.name, <<~RUBY
            update_function :#{function.name} do
              <<~SQL
                #{indent fn_sql}
              SQL
            end
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
              #{indent function.description || ""}
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
