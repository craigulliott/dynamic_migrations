module DynamicMigrations
  module Postgres
    class Generator
      module Function
        def create_function function, code_comment = nil
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

          # we only provide a table if the function has a single trigger and they
          # are in the same schema, otherwise we can't reliable handle dependencies
          # so the function will be created in the schema's migration
          function_table = nil
          if function.triggers.count == 1 && function.schema == function.triggers.first&.table&.schema
            function_table = function.triggers.first&.table
          end

          add_fragment schema: function.schema,
            table: function_table,
            migration_method: :create_function,
            object: function,
            code_comment: code_comment,
            migration: comment_sql + <<~RUBY
              create_function :#{function.name}#{optional_options_syntax} do
                <<~SQL
                  #{indent fn_sql, 2}
                SQL
              end
            RUBY
        end

        def update_function function, code_comment = nil
          fn_sql = function.definition.strip

          add_fragment schema: function.schema,
            table: function.triggers.first&.table,
            migration_method: :update_function,
            object: function,
            code_comment: code_comment,
            migration: <<~RUBY
              update_function :#{function.name} do
                <<~SQL
                  #{indent fn_sql, 2}
                SQL
              end
            RUBY
        end

        def drop_function function, code_comment = nil
          add_fragment schema: function.schema,
            table: function.triggers.first&.table,
            migration_method: :drop_function,
            object: function,
            code_comment: code_comment,
            migration: <<~RUBY
              drop_function :#{function.name}
            RUBY
        end

        # add a comment to a function
        def set_function_comment function, code_comment = nil
          add_fragment schema: function.schema,
            table: function.triggers.first&.table,
            migration_method: :set_function_comment,
            object: function,
            code_comment: code_comment,
            migration: <<~RUBY
              set_function_comment :#{function.name}, <<~COMMENT
                #{indent function.description || ""}
              COMMENT
            RUBY
        end

        # remove the comment from a function
        def remove_function_comment function, code_comment = nil
          add_fragment schema: function.schema,
            table: function.triggers.first&.table,
            migration_method: :remove_function_comment,
            object: function,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_function_comment :#{function.name}
            RUBY
        end
      end
    end
  end
end
