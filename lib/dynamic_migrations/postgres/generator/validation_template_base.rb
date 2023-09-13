module DynamicMigrations
  module Postgres
    class Generator
      class ValidationTemplateBase
        class TemplateError < StandardError
        end

        attr_reader :validation

        def initialize validation, code_comment
          @validation = validation
          @code_comment = code_comment
        end

        private

        def assert_not_deferred!
          if @validation.initially_deferred || @validation.deferrable
            raise TemplateError, "#{self.class.name} validation template requires constraints to be are not deferrable"
          end
        end

        def assert_column_count! count = 1
          if @validation.columns.count != count
            raise TemplateError, "#{self.class.name} validation template requires a validation with only #{count} column"
          end
        end

        def first_column
          column = @validation.columns.first
          if column.nil?
            raise TemplateError, "#{self.class.name} validation template requires a first column"
          end
          column
        end

        def value_from_check_clause regex
          matches = @validation.check_clause.strip.match(regex)
          unless matches
            raise TemplateError, "#{self.class.name} validation template check_clause was not an expected format"
          end
          if matches[:value].nil?
            raise TemplateError, "#{self.class.name} validation template check_clause could not parse out value from regex (expected `value` named capture group in the regex)"
          end
          matches[:value]
        end

        def name_and_description_options_string default_name
          options = {}
          # we only need to provide a name if it is different than the default
          unless @validation.name == default_name
            options[:name] = @validation.name
          end
          # only provide a comment if it is not nil
          unless @validation.description.nil?
            options[:comment] = <<~RUBY
              <<~COMMENT
                #{indent @validation.description || ""}
              COMMENT
            RUBY
          end

          options_string = options.map { |k, v| "#{k}: #{v}" }.join(", ")
          options_string.empty? ? nil : ", #{options_string}"
        end

        def indent multi_line_string, levels = 1
          spaces = "  " * levels
          multi_line_string.gsub("\n", "\n#{spaces}")
        end
      end
    end
  end
end
