module DynamicMigrations
  module Postgres
    class Generator
      module Trigger
        def add_trigger trigger, code_comment = nil
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

          add_fragment schema: trigger.table.schema,
            table: trigger.table,
            migration_method: :add_trigger,
            object: trigger,
            code_comment: code_comment,
            migration: <<~RUBY
              #{method_name} :#{trigger.table.name}, #{options_syntax}
            RUBY
        end

        def remove_trigger trigger, code_comment = nil
          add_fragment schema: trigger.table.schema,
            table: trigger.table,
            migration_method: :remove_trigger,
            object: trigger,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_trigger :#{trigger.table.name}, :#{trigger.name}
            RUBY
        end

        def recreate_trigger original_trigger, updated_trigger
          # remove the original trigger
          removal_fragment = remove_trigger original_trigger, <<~CODE_COMMENT
            Removing original trigger because it has changed (it is recreated below)
            Changes:
              #{indent original_trigger.differences_descriptions(updated_trigger).join("\n")}
          CODE_COMMENT

          # recrete the trigger with the new options
          recreation_fragment = add_trigger updated_trigger, <<~CODE_COMMENT
            Recreating this trigger
          CODE_COMMENT

          # return the new fragments (the main reason to return them here is for the specs)
          [removal_fragment, recreation_fragment]
        end

        # add a comment to a trigger
        def set_trigger_comment trigger, code_comment = nil
          description = trigger.description

          if description.nil?
            raise MissingDescriptionError
          end

          add_fragment schema: trigger.table.schema,
            table: trigger.table,
            migration_method: :set_trigger_comment,
            object: trigger,
            code_comment: code_comment,
            migration: <<~RUBY
              set_trigger_comment :#{trigger.table.name}, :#{trigger.name}, <<~COMMENT
                #{indent description}
              COMMENT
            RUBY
        end

        # remove the comment from a trigger
        def remove_trigger_comment trigger, code_comment = nil
          add_fragment schema: trigger.table.schema,
            table: trigger.table,
            migration_method: :remove_trigger_comment,
            object: trigger,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_trigger_comment :#{trigger.table.name}, :#{trigger.name}
            RUBY
        end
      end
    end
  end
end
