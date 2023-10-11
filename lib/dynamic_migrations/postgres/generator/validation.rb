module DynamicMigrations
  module Postgres
    class Generator
      module Validation
        class UnexpectedTemplateError < StandardError
        end

        class TemplateAlreadyExistsError < StandardError
        end

        def self.template template_name
          @templates && @templates[template_name]
        end

        def self.has_template? template_name
          @templates&.key?(template_name) || false
        end

        # install a template into the migration generator, this can be used from outside this
        # library to clean up common migrations (replace common migrations with syntatic sugar)
        def self.add_template name, template_class
          @templates ||= {}
          raise TemplateAlreadyExistsError, name if @templates.key?(name)
          @templates[name] = template_class
        end

        def add_validation validation, code_comment = nil
          # if we have a corresponding template, then use it
          if validation.template
            unless (template_class = Validation.template(validation.template))
              raise UnexpectedTemplateError, "Unrecognised template #{validation.template}"
            end

            arguments = template_class.new(validation, code_comment).fragment_arguments
            add_fragment(**arguments)

          # no template, process this as a default validation (takes all options)
          else

            options = {
              name: ":#{validation.name}"
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

            add_fragment schema: validation.table.schema,
              table: validation.table,
              migration_method: :add_validation,
              object: validation,
              code_comment: code_comment,
              migration: comment_sql + <<~RUBY
                add_validation :#{validation.table.name}, #{options_syntax} do
                  <<~SQL
                    #{indent validation_sql}
                  SQL
                end
              RUBY
          end
        end

        def remove_validation validation, code_comment = nil
          add_fragment schema: validation.table.schema,
            table: validation.table,
            migration_method: :remove_validation,
            object: validation,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_validation :#{validation.table.name}, :#{validation.name}
            RUBY
        end

        def recreate_validation original_validation, updated_validation
          # remove the original validation
          removal_fragment = remove_validation original_validation, <<~CODE_COMMENT
            Removing original validation because it has changed (it is recreated below)
            Changes:
              #{indent original_validation.differences_descriptions(updated_validation).join("\n")}
          CODE_COMMENT

          # recrete the validation with the new options
          recreation_fragment = add_validation updated_validation, <<~CODE_COMMENT
            Recreating this validation
          CODE_COMMENT

          # return the new fragments (the main reason to return them here is for the specs)
          [removal_fragment, recreation_fragment]
        end

        # add a comment to a validation
        def set_validation_comment validation, code_comment = nil
          description = validation.description

          if description.nil?
            raise MissingDescriptionError, "Missing required description for validation `#{validation.name}` in table `#{validation.table.schema.name}.#{validation.table.name}`"
          end

          add_fragment schema: validation.table.schema,
            table: validation.table,
            migration_method: :set_validation_comment,
            object: validation,
            code_comment: code_comment,
            migration: <<~RUBY
              set_validation_comment :#{validation.table.name}, :#{validation.name}, <<~COMMENT
                #{indent description}
              COMMENT
            RUBY
        end

        # remove the comment from a validation
        def remove_validation_comment validation, code_comment = nil
          add_fragment schema: validation.table.schema,
            table: validation.table,
            migration_method: :remove_validation_comment,
            object: validation,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_validation_comment :#{validation.table.name}, :#{validation.name}
            RUBY
        end
      end
    end
  end
end
