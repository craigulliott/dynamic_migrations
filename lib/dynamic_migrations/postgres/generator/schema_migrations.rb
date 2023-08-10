module DynamicMigrations
  module Postgres
    class Generator
      class SchemaMigrations
        class SectionNotFoundError < StandardError
        end

        attr_reader :current_migration_sections

        def initialize
          @migrations = []
          @current_migration_sections = []
        end

        def add_content schema_name, table_name, content_type, object_name, content
          @current_migration_sections << Section.new(schema_name, table_name, content_type, object_name, content)
        end

        def finalize
          if @current_migration_sections.any?

            contents = []
            @current_migration_sections.each do |section|
              contents << section.content.strip
              # add an empty line between sections (unless this is a comment section)
              unless section.content_type? :comment
                contents << ""
              end
            end

            @migrations << {
              name: generate_current_migration_name,
              content: contents.join("\n").strip
            }

            @current_migration_sections = []
          end
        end

        def to_a
          @migrations
        end

        private

        def current_migration_has_content_type? content_type
          @current_migration_sections.map(&:content_type).include? content_type
        end

        def current_migration_section_of_content_type content_type
          section = @current_migration_sections.find(&:content_type)
          if section.nil?
            raise SectionNotFoundError, "No section of type #{content_type} found"
          end
          section
        end

        # return true if the current migration only has the provided content types and comments
        def current_migration_only_content_types? content_types
          (@current_migration_sections.map(&:content_type) - content_types - [:comment]).empty?
        end

        def generate_current_migration_name
          if current_migration_has_content_type? :create_schema
            "create_#{current_migration_section_of_content_type(:create_schema).schema_name}_schema".to_sym

          elsif current_migration_has_content_type? :drop_schema
            "drop_#{current_migration_section_of_content_type(:drop_schema).schema_name}_schema".to_sym

          elsif current_migration_has_content_type? :create_table
            "create_#{current_migration_section_of_content_type(:create_table).table_name}".to_sym

          elsif current_migration_has_content_type? :drop_table
            "drop_#{current_migration_section_of_content_type(:drop_table).table_name}".to_sym

          elsif current_migration_only_content_types? [:create_function]
            "create_function_#{@current_migration_sections.find { |s| s.content_type == :create_function }&.object_name}".to_sym

          elsif current_migration_only_content_types? [:create_function, :update_function, :drop_function, :set_function_comment, :remove_function_comment]
            :schema_functions

          elsif @current_migration_sections.first&.table_name
            "changes_for_#{@current_migration_sections.first&.table_name}".to_sym

          else
            :changes
          end
        end
      end
    end
  end
end
