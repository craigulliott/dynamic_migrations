module DynamicMigrations
  module Postgres
    class Generator
      class Migration
        class UnexpectedSchemaError < StandardError
        end

        class SectionNotFoundError < StandardError
        end

        class UnexpectedMigrationMethodNameError < StandardError
        end

        class DuplicateStructureTemplateError < StandardError
        end

        class NoFragmentsError < StandardError
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

        attr_reader :schema_name
        attr_reader :fragments

        def initialize schema_name
          @schema_name = schema_name
          @fragments = []
        end

        # Add a migration fragment to this migration, if the migration is not
        # configured (via a structure template) to handle the method_name of the
        # fragment, then am error is raised. An error will also be raised if the
        # migration belongs to a different schema than the provided fragment.
        def add_fragment fragment
          raise UnexpectedSchemaError unless @schema_name == fragment.schema_name

          unless supported_migration_method? fragment.migration_method
            raise UnexpectedMigrationMethodNameError, "Expected method to be a valid migrator method, got `#{fragment.migration_method}`"
          end

          @fragments << fragment

          fragment
        end

        # Return an array of table dependencies for this migration, this array comes from
        # combining any table dependencies from each fragment.
        # Will raise an error if no fragments have been provided.
        def dependencies
          raise NoFragmentsError if fragments.empty?
          @fragments.map(&:dependency).compact
        end

        # removes and returns any fragments which have a dependency on the table with the
        # provided schema_name and table_name, this is used for extracting fragments which
        # cause circular dependencies so they can be placed into their own migrations
        def extract_fragments_with_dependency schema_name, table_name
          results = @fragments.filter { |f| f.is_dependent_on? schema_name, table_name }
          # remove any of these from the internal array of fragments
          @fragments.filter! { |f| !f.is_dependent_on?(schema_name, table_name) }
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
            "create_#{first_fragment_using_migration_method(:create_schema).schema_name}_schema".to_sym

          elsif fragments_for_method? :drop_schema
            "drop_#{first_fragment_using_migration_method(:drop_schema).schema_name}_schema".to_sym

          elsif fragments_for_method? :create_table
            "create_#{first_fragment_using_migration_method(:create_table).table_name}".to_sym

          elsif fragments_for_method? :drop_table
            "drop_#{first_fragment_using_migration_method(:drop_table).table_name}".to_sym

          elsif all_fragments_for_method? [:create_function]
            "create_function_#{@fragments.find { |s| s.migration_method == :create_function }&.object_name}".to_sym

          elsif all_fragments_for_method? [:create_function, :update_function, :drop_function, :set_function_comment, :remove_function_comment]
            :schema_functions

          elsif @fragments.first&.table_name
            "changes_for_#{@fragments.first&.table_name}".to_sym

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
