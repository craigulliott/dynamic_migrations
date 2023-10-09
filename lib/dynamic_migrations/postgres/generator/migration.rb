module DynamicMigrations
  module Postgres
    class Generator
      class Migration
        class SectionNotFoundError < StandardError
        end

        class UnexpectedMigrationMethodNameError < StandardError
        end

        class DuplicateStructureTemplateError < StandardError
        end

        class NoFragmentsError < StandardError
        end

        class MissingRequiredTableName < StandardError
        end

        class MissingRequiredSchemaName < StandardError
        end

        class UnexpectedTableError < StandardError
        end

        class UnexpectedSchemaError < StandardError
        end

        attr_reader :table_name
        attr_reader :schema_name
        attr_reader :fragments

        # schema_name and table_name can be nil
        def initialize schema_name = nil, table_name = nil
          @schema_name = schema_name
          @table_name = table_name
          @fragments = []
        end

        # Defines a new section in the migration file, this is used to group
        # migration fragments of the provided method names together under the
        # provided header
        def self.add_structure_template method_names, header
          @structure_templates ||= []

          if (@structure_templates.map { |s| s[:methods] }.flatten & method_names).any?
            raise DuplicateStructureTemplateError, "Duplicate structure template for methods `#{method_names}`"
          end

          @structure_templates << {
            methods: method_names,
            header_comment: <<~COMMENT.strip
              #
              # #{header.strip}
              #
            COMMENT
          }
        end

        # return the list of structure templates for use in this migration
        def self.structure_templates
          @structure_templates || []
        end

        # return the list of structure templates for use in this migration
        def self.clear_structure_templates
          @structure_templates = []
        end

        def to_s
          <<~PREVIEW.strip
            # Migration content preview
            # -------------------------
            # Schema: #{@schema_name}
            # Table: #{@table_name}

            # Table Dependencies (count: #{table_dependencies.count}):
            #   #{table_dependencies.map { |d| "Schema: `#{d[:schema_name]}` Table: `#{d[:table_name]}`" }.join("\n#   ")}

            # Enum Dependencies (count: #{enum_dependencies.count}):
            #   #{enum_dependencies.map { |d| "Schema: `#{d[:schema_name]}` Enum: `#{d[:enum_name]}`" }.join("\n#   ")}

            # Function Dependencies (count: #{function_dependencies.count}):
            #   #{function_dependencies.map { |d| "Schema: `#{d[:schema_name]}` Function: `#{d[:function_name]}`" }.join("\n#   ")}

            # Fragment Count:
            # Fragments (count: #{fragments.count}):

            #{fragments.map(&:to_s).join("\n\n")}
          PREVIEW
        end

        # Add a migration fragment to this migration, if the migration is not
        # configured (via a structure template) to handle the method_name of the
        # fragment, then am error is raised. An error will also be raised if the
        # migration belongs to a different schema than the provided fragment.
        def add_fragment fragment
          unless supported_migration_method? fragment.migration_method
            raise UnexpectedMigrationMethodNameError, "Expected method to be a valid migrator method, got `#{fragment.migration_method}`"
          end

          # confirm the fragment is for this schema (even if both
          # these values are nil/there is no schema)
          unless @schema_name == fragment.schema_name
            raise UnexpectedSchemaError, "Fragment is for schema `#{fragment.schema_name || "nil"}` but migration is for schema `#{@schema_name || "nil"}`"
          end

          # confirm this fragment is for this table, this works for database and schame
          # migrations to, as all values should be nil
          unless @table_name == fragment.table_name
            raise UnexpectedTableError, "Fragment is for table `#{fragment.table_name || "nil"}` but migration is for table `#{@table_name || "nil"}`"
          end

          @fragments << fragment

          fragment
        end

        # Return an array of table dependencies for this migration, this array comes from
        # combining any table dependencies from each fragment.
        # Will raise an error if no fragments are available.
        def table_dependencies
          raise NoFragmentsError if fragments.empty?
          @fragments.map(&:table_dependency).compact.uniq
        end

        # Return an array of function dependencies for this migration, this array comes from
        # combining any function dependencies from each fragment.
        # Will raise an error if no fragments are available.
        def function_dependencies
          raise NoFragmentsError if fragments.empty?
          @fragments.map(&:function_dependency).compact.uniq
        end

        # Return an array of enum dependencies for this migration, this array comes from
        # combining any enum dependencies from each fragment.
        # Will raise an error if no fragments are available.
        def enum_dependencies
          raise NoFragmentsError if fragments.empty?
          @fragments.map(&:enum_dependency).compact.uniq
        end

        # returns the number of fragment within this migration which have the provided dependency
        def fragments_with_table_dependency_count schema_name, table_name
          @fragments.count { |f| f.is_dependent_on_table? schema_name, table_name }
        end

        # removes and returns any fragments which have a dependency on the table with the
        # provided schema_name and table_name, this is used for extracting fragments which
        # cause circular dependencies so they can be placed into their own migrations
        def extract_fragments_with_table_dependency schema_name, table_name
          results = @fragments.filter { |f| f.is_dependent_on_table? schema_name, table_name }
          # remove any of these from the internal array of fragments
          @fragments.filter! { |f| !f.is_dependent_on_table?(schema_name, table_name) }
          # return the results
          results
        end

        # Combine the fragments, and build a string representation of the migration
        # using the structure templates defined in this class.
        # Will raise an error if no fragments have been provided.
        def content
          raise NoFragmentsError if fragments.empty?
          sections = []
          self.class.structure_templates.each do |section|
            # add the header comment if we have a migration which matches one of the
            # methods in this section
            if (section[:methods] & @fragments.map(&:migration_method)).any?
              sections << section[:header_comment].strip
            end

            # iterate through this sections methods in order and look
            # for any that match the migrations we have
            section[:methods].each do |migration_method|
              # if we have any migration fragments for this method then add them
              @fragments.filter { |f| f.migration_method == migration_method }.each do |fragment|
                sections << fragment.to_s
                sections << ""
              end
            end
          end
          sections.join("\n").strip
        end

        # Using the migration fragments, generate a friendly/descriptive name for the migration.
        # Will raise an error if no fragments have been provided.
        def name
          raise NoFragmentsError if fragments.empty?

          if fragments_for_method? :create_schema
            :"create_#{fragments.first&.object_name}_schema"

          elsif fragments_for_method? :drop_schema
            :"drop_#{fragments.first&.object_name}_schema"

          elsif fragments_for_method? :create_table
            :"create_#{first_fragment_using_migration_method(:create_table).table_name}"

          elsif fragments_for_method? :drop_table
            :"drop_#{first_fragment_using_migration_method(:drop_table).table_name}"

          elsif all_fragments_for_method? [:create_function]
            :"create_function_#{@fragments.find { |s| s.migration_method == :create_function }&.object_name}"

          elsif all_fragments_for_method? [:create_function, :update_function, :drop_function, :set_function_comment, :remove_function_comment]
            :schema_functions

          elsif all_fragments_for_method? [:create_enum, :add_enum_values, :drop_enum, :set_enum_comment, :remove_enum_comment]
            :enums

          elsif all_fragments_for_method? [:enable_extension]
            (@fragments.count > 1) ? :enable_extensions : :"enable_#{fragments.first&.object_name}_extension"

          elsif all_fragments_for_method? [:disable_extension]
            (@fragments.count > 1) ? :disable_extensions : :"disable_#{fragments.first&.object_name}_extension"

          elsif @fragments.first&.table_name
            :"changes_for_#{@fragments.first&.table_name}"

          else
            :changes
          end
        end

        private

        def supported_migration_method? method_name
          self.class.structure_templates.map { |s| s[:methods] }.flatten.include? method_name
        end

        def fragments_for_method? migration_method
          @fragments.map(&:migration_method).include? migration_method
        end

        def first_fragment_using_migration_method migration_method
          fragment = @fragments.find(&:migration_method)
          if fragment.nil?
            raise SectionNotFoundError, "No fragment of type #{migration_method} found"
          end
          fragment
        end

        # return true if the current migration only has the provided content types and comments
        def all_fragments_for_method? migration_methods
          (@fragments.map(&:migration_method) - migration_methods - [:comment]).empty?
        end
      end
    end
  end
end
