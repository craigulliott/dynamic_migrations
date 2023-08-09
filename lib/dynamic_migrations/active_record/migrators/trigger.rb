module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Trigger
        # create a trigger
        class UnexpectedEventManipulationError < StandardError
        end

        class UnexpectedActionOrientationError < StandardError
        end

        class UnexpectedActionTimingError < StandardError
        end

        class UnexpectedConditionsError < StandardError
        end

        # create a postgres trigger
        def add_trigger table_name, name:, action_timing:, event_manipulation:, action_orientation:, function_schema_name:, function_name:, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, comment: nil
          unless [:insert, :delete, :update].include? event_manipulation
            raise UnexpectedEventManipulationError, event_manipulation
          end

          unless action_condition.nil? || action_condition.is_a?(String)
            raise UnexpectedConditionsError, "expected String but got `#{action_condition}`"
          end

          unless [:row, :statement].include? action_orientation
            raise UnexpectedActionOrientationError, action_orientation
          end

          unless [:before, :after, :instead_of].include? action_timing
            raise UnexpectedActionTimingError, action_timing
          end

          # "INSTEAD OF/BEFORE/AFTER" "INSERT/UPDATE/DELETE"
          timing_sql = "#{action_timing.to_s.sub("_", " ")} #{event_manipulation}".upcase

          condition_sql = action_condition.nil? ? "" : "WHEN (#{action_condition})"

          temp_tables = []
          unless action_reference_old_table.nil?
            temp_tables << "OLD TABLE AS #{action_reference_old_table}"
          end
          unless action_reference_new_table.nil?
            temp_tables << "NEW TABLE AS #{action_reference_new_table}"
          end
          temp_tables_sql = temp_tables.any? ? "REFERENCING #{temp_tables.join(" ")}" : ""

          # schema_name was not provided to this method, it comes from the migration class
          execute <<~SQL
            CREATE TRIGGER #{name}
              #{timing_sql} ON #{schema_name}.#{table_name} #{temp_tables_sql}
                FOR EACH #{action_orientation}
                  #{condition_sql}
                  EXECUTE FUNCTION #{function_schema_name}.#{function_name}();
          SQL

          if comment.is_a? String
            set_trigger_comment table_name, name, comment
          end
        end

        # wrappers for add_trigger which provide more friendly syntax
        def before_insert table_name, name:, function_schema_name:, function_name:, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, comment: nil
          add_trigger table_name, name: name, action_timing: :before, event_manipulation: :insert, action_orientation: :row, function_schema_name: function_schema_name, function_name: function_name, action_condition: action_condition, action_reference_old_table: action_reference_old_table, action_reference_new_table: action_reference_new_table, comment: comment
        end

        def before_update table_name, name:, function_schema_name:, function_name:, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, comment: nil
          add_trigger table_name, name: name, action_timing: :before, event_manipulation: :update, action_orientation: :row, function_schema_name: function_schema_name, function_name: function_name, action_condition: action_condition, action_reference_old_table: action_reference_old_table, action_reference_new_table: action_reference_new_table, comment: comment
        end

        def before_delete table_name, name:, function_schema_name:, function_name:, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, comment: nil
          add_trigger table_name, name: name, action_timing: :before, event_manipulation: :delete, action_orientation: :row, function_schema_name: function_schema_name, function_name: function_name, action_condition: action_condition, action_reference_old_table: action_reference_old_table, action_reference_new_table: action_reference_new_table, comment: comment
        end

        def after_insert table_name, name:, function_schema_name:, function_name:, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, comment: nil
          add_trigger table_name, name: name, action_timing: :after, event_manipulation: :insert, action_orientation: :row, function_schema_name: function_schema_name, function_name: function_name, action_condition: action_condition, action_reference_old_table: action_reference_old_table, action_reference_new_table: action_reference_new_table, comment: comment
        end

        def after_update table_name, name:, function_schema_name:, function_name:, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, comment: nil
          add_trigger table_name, name: name, action_timing: :after, event_manipulation: :update, action_orientation: :row, function_schema_name: function_schema_name, function_name: function_name, action_condition: action_condition, action_reference_old_table: action_reference_old_table, action_reference_new_table: action_reference_new_table, comment: comment
        end

        def after_delete table_name, name:, function_schema_name:, function_name:, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, comment: nil
          add_trigger table_name, name: name, action_timing: :after, event_manipulation: :delete, action_orientation: :row, function_schema_name: function_schema_name, function_name: function_name, action_condition: action_condition, action_reference_old_table: action_reference_old_table, action_reference_new_table: action_reference_new_table, comment: comment
        end

        def remove_trigger table_name, trigger_name
          execute <<~SQL
            DROP TRIGGER #{trigger_name} ON #{schema_name}.#{table_name};
          SQL
        end

        def set_trigger_comment table_name, trigger_name, comment
          execute <<~SQL
            COMMENT ON TRIGGER #{trigger_name} ON #{schema_name}.#{table_name} IS '#{quote comment}';
          SQL
        end

        def remove_trigger_comment table_name, trigger_name
          execute <<~SQL
            COMMENT ON TRIGGER #{trigger_name} ON #{schema_name}.#{table_name} IS NULL;
          SQL
        end
      end
    end
  end
end
