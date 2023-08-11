module DynamicMigrations
  module Postgres
    class Generator
      class ExpectedSymbolError < StandardError
      end

      class DeferrableOptionsError < StandardError
      end

      class UnexpectedMigrationMethodNameError < StandardError
      end

      class MissingDescriptionError < StandardError
      end

      class NoDifferenceError < StandardError
      end

      # these sections are in order for which they will appear in a migration,
      # note that removals come before additions, and that the order here optomizes
      # for dependencies (i.e. columns have to be created before indexes are added and
      # triggers are removed before functions are dropped)
      STRUCTURE = [
        {
          header_comment: <<~COMMENT,
            #
            # Remove Functions
            #
          COMMENT
          methods: [
            :remove_function_comment,
            :drop_function
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Remove Triggers
            #
          COMMENT
          methods: [
            :remove_trigger_comment,
            :remove_trigger
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Remove Validations
            #
          COMMENT
          methods: [
            :remove_validation,
            :remove_unique_constraint
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Remove Foreign Keys
            #
          COMMENT
          methods: [
            :remove_foreign_key
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Remove Primary Keys
            #
          COMMENT
          methods: [
            :remove_primary_key
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Remove Indexes
            #
          COMMENT
          methods: [
            :remove_index,
            :remove_index_comment
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Remove Columns
            #
          COMMENT
          methods: [
            :remove_column
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Remove Tables
            #
          COMMENT
          break_after: true,
          methods: [
            :drop_table
          ]
        },
        {
          # this is important enough to get it's own migration
          break_before: true,
          break_after: true,
          header_comment: <<~COMMENT,
            #
            # Drop this schema
            #
          COMMENT
          methods: [
            :drop_schema
          ]
        },
        {
          # this is important enough to get it's own migration
          break_before: true,
          break_after: true,
          header_comment: <<~COMMENT,
            #
            # Create this schema
            #
          COMMENT
          methods: [
            :create_schema
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Create Table
            #
          COMMENT
          methods: [
            :create_table
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Tables
            #
          COMMENT
          methods: [
            :remove_table_comment,
            :set_table_comment
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Additional Columns
            #
          COMMENT
          methods: [
            :add_column
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Update Columns
            #
          COMMENT
          methods: [
            :change_column,
            :remove_column_comment,
            :set_column_comment
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Primary Key
            #
          COMMENT
          methods: [
            :add_primary_key
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Indexes
            #
          COMMENT
          methods: [
            :add_index,
            :set_index_comment
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Foreign Keys
            #
          COMMENT
          methods: [
            :add_foreign_key,
            :set_foreign_key_constraint_comment,
            :remove_foreign_key_constraint_comment
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Validations
            #
          COMMENT
          methods: [
            :add_validation,
            :add_unique_constraint,
            :set_validation_comment,
            :remove_validation_comment,
            :set_unique_constraint_comment,
            :remove_unique_constraint_comment
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Functions
            #
          COMMENT
          methods: [
            :create_function
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Triggers
            #
          COMMENT
          methods: [
            :add_trigger,
            :set_trigger_comment
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Update Functions
            #
          COMMENT
          methods: [
            :update_function,
            :set_function_comment
          ]
        }
      ]

      include Schema
      include Table
      include Column
      include ForeignKeyConstraint
      include Index
      include PrimaryKey
      include UniqueConstraint
      include Validation
      include Function
      include Trigger

      def initialize
        @migrations = {}
      end

      # builds an array of migrations that can be used to create the provided schema
      def migrations
        final_migrations = {}
        # an array of table names which have migrations, we group migrations for the same table together
        @migrations.map do |schema_name, table_migrations|
          schema_migrations = SchemaMigrations.new
          # iterate through the tables which have migrations
          table_migrations.map do |table_name, fragments|
            # iterate through the structure object in order, and create the final migrations
            STRUCTURE.each do |section|
              # if this section requires a new migration, then end any current one
              if section[:break_before]
                schema_migrations.finalize
              end

              # add the header comment if we have a migration which matches one of the
              # methods in this section
              if (section[:methods] & fragments.keys).any?
                header_fragment = Fragment.new nil, nil, section[:header_comment]
                schema_migrations.add_fragment schema_name, table_name, :comment, header_fragment
              end

              # iterate through this sections methods in order and look
              # for any that match the migrations we have
              section[:methods].each do |method_name|
                # if we have any migration fragments for this method then add them
                fragments[method_name]&.each do |fragment|
                  schema_migrations.add_fragment schema_name, table_name, method_name, fragment
                end
              end

              # if this section causes a new migration then end any current one
              if section[:break_after]
                schema_migrations.finalize
              end
            end
            schema_migrations.finalize
          end
          final_migrations[schema_name] = schema_migrations.to_a
        end
        final_migrations
      end

      private

      def supported_migration_method_names
        @supported_migration_method_names ||= STRUCTURE.map { |s| s[:methods] }.flatten
      end

      def supported_migration_method? method_name
        supported_migration_method_names.include? method_name
      end

      def add_migration schema_name, table_name, migration_method, object_name, code_comment, migration
        raise ExpectedSymbolError, "Expected schema_name to be a symbol, got #{schema_name}" unless schema_name.is_a?(Symbol)
        raise ExpectedSymbolError, "Expected table_name to be a symbol, got #{table_name}" unless schema_name.is_a?(Symbol)

        unless supported_migration_method? migration_method
          raise UnexpectedMigrationMethodNameError, "Expected migration_method to be a valid migrator method, got `#{migration_method}`"
        end

        final_migration = strip_empty_lines(migration).strip
        fragment = Fragment.new(object_name, code_comment, final_migration)

        # note, table_name can be nil, which is OK because nil is a valid
        # key and we do want to group them all together
        @migrations[schema_name] ||= {}
        @migrations[schema_name][table_name] ||= {}
        @migrations[schema_name][table_name][migration_method] ||= []
        @migrations[schema_name][table_name][migration_method] << fragment

        # return the newly created migration fragment
        fragment
      end

      def indent multi_line_string
        multi_line_string.gsub("\n", "\n  ")
      end

      def strip_empty_lines multi_line_string
        multi_line_string.gsub(/^\s*\n/, "")
      end
    end
  end
end
