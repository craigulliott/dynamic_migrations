module DynamicMigrations
  module Postgres
    class Generator
      class Fragment
        attr_reader :schema_name
        attr_reader :table_name
        attr_reader :migration_method
        attr_reader :object_name
        attr_reader :dependency_schema_name
        attr_reader :dependency_table_name

        def initialize schema_name, table_name, migration_method, object_name, code_comment, content
          @schema_name = schema_name
          @table_name = table_name
          @migration_method = migration_method
          @object_name = object_name
          @code_comment = code_comment
          @content = content
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
        def dependency
          if dependency_schema_name && dependency_table_name
            {
              schema_name: dependency_schema_name,
              table_name: dependency_table_name
            }
          end
        end

        # returns true if the fragment has a table dependency, and the dependency matches
        # the provided schema_name and table_name, otherwise returns false.
        def is_dependent_on? schema_name, table_name
          dependency_schema_name && schema_name == dependency_schema_name && table_name == dependency_table_name || false
        end

        # Set the table table dependency for this fragment. Takes a schema name and
        # table name
        def set_dependent_table schema_name, table_name
          @dependency_schema_name = schema_name
          @dependency_table_name = table_name
        end
      end
    end
  end
end
