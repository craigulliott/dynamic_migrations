module DynamicMigrations
  module Postgres
    class Generator
      class TriggerTemplateBase
        class TemplateError < StandardError
        end

        attr_reader :trigger
        attr_reader :code_comment

        def initialize trigger, code_comment
          @trigger = trigger
          @code_comment = code_comment
        end

        private

        def assert_column_count! count = 1
          if @trigger.columns.count != count
            raise TemplateError, "#{self.class.name} trigger template requires a trigger with only #{count} column"
          end
        end

        def first_column
          column = @trigger.columns.first
          if column.nil?
            raise TemplateError, "#{self.class.name} trigger template requires a first column"
          end
          column
        end

        def indent multi_line_string, levels = 1
          spaces = "  " * levels
          multi_line_string.gsub("\n", "\n#{spaces}")
        end
      end
    end
  end
end
