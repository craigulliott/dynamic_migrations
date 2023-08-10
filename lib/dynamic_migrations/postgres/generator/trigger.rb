module DynamicMigrations
  module Postgres
    class Generator
      module Trigger
        def add_trigger trigger
          options = {
            name: ":#{trigger.name}"
          }

          # if the trigger is a row trigger and the action timing is before or after
          # then we can use some syntactic sugar to make the migration look nicer
          # we use method names like before_insert, after_update, etc. and drop the
          # unnessessary options
          if trigger.action_orientation == :row && [:before, :after].include?(trigger.action_timing)
            method_name = "#{trigger.action_timing}_#{trigger.event_manipulation}"
          else
            method_name = "add_trigger"
            options[:action_timing] = ":#{trigger.action_timing}"
            options[:event_manipulation] = ":#{trigger.event_manipulation}"
            options[:action_orientation] = ":#{trigger.action_orientation}"
          end

          # added here because we want the timing and manipulation to visually appear first
          options[:function_schema_name] = ":#{trigger.function.schema.name}"
          options[:function_name] = ":#{trigger.function.name}"

          unless trigger.action_condition.nil?
            options[:action_condition] = ":#{trigger.action_condition}"
          end

          unless trigger.action_reference_old_table.nil?
            options[:action_reference_old_table] = ":#{trigger.action_reference_old_table}"
          end

          unless trigger.action_reference_new_table.nil?
            options[:action_reference_new_table] = ":#{trigger.action_reference_new_table}"
          end

          unless trigger.description.nil?
            options[:comment] = <<~RUBY
              <<~COMMENT
                #{indent trigger.description}
              COMMENT
            RUBY
          end

          options_syntax = options.map { |k, v| "#{k}: #{v}" }.join(", ")

          add_migration trigger.table.schema.name, trigger.table.name, :add_trigger, trigger.name, <<~RUBY
            #{method_name} :#{trigger.table.name}, #{options_syntax}
          RUBY
        end

        def remove_trigger trigger
          add_migration trigger.table.schema.name, trigger.table.name, :remove_trigger, trigger.name, <<~RUBY
            remove_trigger :#{trigger.table.name}, :#{trigger.name}
          RUBY
        end

        # add a comment to a trigger
        def set_trigger_comment trigger
          add_migration trigger.table.schema.name, trigger.table.name, :set_trigger_comment, trigger.name, <<~RUBY
            set_trigger_comment :#{trigger.table.name}, :#{trigger.name}, <<~COMMENT
              #{indent trigger.description}
            COMMENT
          RUBY
        end

        # remove the comment from a trigger
        def remove_trigger_comment trigger
          add_migration trigger.table.schema.name, trigger.table.name, :remove_trigger_comment, trigger.name, <<~RUBY
            remove_trigger_comment :#{trigger.table.name}, :#{trigger.name}
          RUBY
        end
      end
    end
  end
end
