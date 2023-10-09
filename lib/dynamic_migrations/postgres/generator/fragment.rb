module DynamicMigrations
  module Postgres
    class Generator
      class Fragment
        class InvalidNameError < StandardError
        end

        class ContentRequiredError < StandardError
        end

        attr_reader :schema_name
        attr_reader :table_name
        attr_reader :migration_method
        attr_reader :object_name
        attr_reader :dependency_schema_name
        attr_reader :dependency_table_name
        attr_reader :dependency_function_name
        attr_reader :dependency_enum_name

        def initialize schema_name, table_name, migration_method, object_name, code_comment, content
          valid_name_regex = /\A[a-z][a-z0-9]*(_[a-z0-9]+)*\z/

          unless schema_name.nil? || (schema_name.to_s.match valid_name_regex)
            raise InvalidNameError, "Invalid schema name `#{schema_name}`, must only be lowercase letters, numbers and underscores"
          end
          @schema_name = schema_name

          unless table_name.nil? || (table_name.to_s.match valid_name_regex)
            raise InvalidNameError, "Invalid table name `#{table_name}`, must only be lowercase letters, numbers and underscores"
          end
          @table_name = table_name

          unless object_name.to_s.match valid_name_regex
            raise InvalidNameError, "Invalid object name `#{object_name}`, must only be lowercase letters, numbers and underscores"
          end
          @object_name = object_name

          @migration_method = migration_method
          @code_comment = code_comment&.freeze

          if content.nil?
            raise ContentRequiredError, "Content is required for a fragment"
          end
          @content = content.freeze
        end

        # Returns a string representation of the fragment for use in the final
        # migration. This final string is a combination of the code_comment (if present)
        # and the content of the fragment.
        def to_s
          strings = []
          comment = @code_comment
          unless comment.nil?
            strings << "# " + comment.split("\n").join("\n# ")
          end
          strings << @content
          strings.join("\n").strip
        end

        # Returns true if the fragment has a code comment, otherwise false.
        def has_code_comment?
          !@code_comment.nil?
        end

        # If a table dependency has been set, then returns a hash with the schema_name
        # and table_name, otherwise returns nil.
        def table_dependency
          if dependency_schema_name && dependency_table_name
            {
              schema_name: dependency_schema_name,
              table_name: dependency_table_name
            }
          end
        end

        # If a function dependency has been set, then returns a hash with the schema_name
        # and function_name, otherwise returns nil.
        def function_dependency
          if dependency_schema_name && dependency_function_name
            {
              schema_name: dependency_schema_name,
              function_name: dependency_function_name
            }
          end
        end

        # If an enum dependency has been set, then returns a hash with the schema_name
        # and enum_name, otherwise returns nil.
        def enum_dependency
          if dependency_schema_name && dependency_enum_name
            {
              schema_name: dependency_schema_name,
              enum_name: dependency_enum_name
            }
          end
        end

        # returns true if the fragment has a table dependency, and the dependency matches
        # the provided schema_name and table_name, otherwise returns false.
        def is_dependent_on_table? schema_name, table_name
          dependency_schema_name && schema_name == dependency_schema_name && table_name == dependency_table_name || false
        end

        # Set a table dependency for this fragment. Takes a schema name and
        # table name
        def set_dependent_table schema_name, table_name
          if @dependency_schema_name
            raise "Cannot set a table dependency for a fragment that already has a #{dependency_type} dependency"
          end
          @dependency_schema_name = schema_name
          @dependency_table_name = table_name
        end

        # Set a function dependency for this fragment. Takes a schema name and
        # function name
        def set_dependent_function schema_name, function_name
          if @dependency_schema_name
            raise "Cannot set a table dependency for a fragment that already has a #{dependency_type} dependency"
          end
          @dependency_schema_name = schema_name
          @dependency_function_name = function_name
        end

        # Set an enum dependency for this fragment. Takes a schema name and
        # enum name
        def set_dependent_enum schema_name, enum_name
          if @dependency_schema_name
            raise "Cannot set a table dependency for a fragment that already has a #{dependency_type} dependency"
          end
          @dependency_schema_name = schema_name
          @dependency_enum_name = enum_name
        end

        private

        # returns a symbol representing the type of dependency this fragment has,
        # or nil if there is no dependency
        def dependency_type
          if dependency_function_name
            :function
          elsif dependency_enum_name
            :enum
          elsif dependency_table_name
            :table
          end
        end
      end
    end
  end
end
