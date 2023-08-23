module DynamicMigrations
  module Postgres
    class Generator
      module Enum
        class UnremovableEnumValuesError < StandardError
        end

        def create_enum enum, code_comment = nil
          add_fragment schema: enum.schema,
            migration_method: :create_enum,
            object: enum,
            code_comment: code_comment,
            migration: <<~RUBY
              create_enum :#{enum.name}, [
                :#{enum.values.join(",\n  :")}
              ]
            RUBY
        end

        def update_enum original_enum, updated_enum, code_comment = nil
          added_values = updated_enum.values - original_enum.values
          removed_values = original_enum.values - updated_enum.values

          if removed_values.any?
            raise UnremovableEnumValuesError, "You can not remove enum values from postgres. Tring to remove '#{removed_values.join("', ")}'"
          end

          add_fragment schema: updated_enum.schema,
            migration_method: :add_enum_values,
            object: updated_enum,
            code_comment: code_comment,
            migration: <<~RUBY
              add_enum_values :#{updated_enum.name}, [
                :#{added_values.join(",\n  :")}
              ]
            RUBY
        end

        def drop_enum enum, code_comment = nil
          add_fragment schema: enum.schema,
            migration_method: :drop_enum,
            object: enum,
            code_comment: code_comment,
            migration: <<~RUBY
              drop_enum :#{enum.name}
            RUBY
        end

        # add a comment to a enum
        def set_enum_comment enum, code_comment = nil
          add_fragment schema: enum.schema,
            migration_method: :set_enum_comment,
            object: enum,
            code_comment: code_comment,
            migration: <<~RUBY
              set_enum_comment :#{enum.name}, <<~COMMENT
                #{indent enum.description || ""}
              COMMENT
            RUBY
        end

        # remove the comment from a enum
        def remove_enum_comment enum, code_comment = nil
          add_fragment schema: enum.schema,
            migration_method: :remove_enum_comment,
            object: enum,
            code_comment: code_comment,
            migration: <<~RUBY
              remove_enum_comment :#{enum.name}
            RUBY
        end
      end
    end
  end
end
