module DynamicMigrations
  module Postgres
    class Generator
      class ExpectedSymbolError < StandardError
      end

      class DeferrableOptionsError < StandardError
      end

      class UnexpectedMigrationMethodNameError < StandardError
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
            # Remove Constraints
            #
          COMMENT
          methods: [
            :remove_check_constraint,
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
            :remove_index
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
            # Create Tables
            #
          COMMENT
          methods: [
            :create_table
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
            :update_column
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
            :add_index
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Foreign Keys
            #
          COMMENT
          methods: [
            :add_foreign_key
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Constraints
            #
          COMMENT
          methods: [
            :add_check_constraint,
            :add_unique_constraint
          ]
        },
        {
          header_comment: <<~COMMENT,
            #
            # Functions
            #
          COMMENT
          methods: [
            :create_function,
            :set_function_comment
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
            :update_function
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
      include FixIndentation
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
          table_migrations.map do |table_name, migrations|
            # iterate through the structure object in order, and create the final migrations
            STRUCTURE.each do |section|
              # if this section requires a new migration, then end any current one
              if section[:break_before]
                schema_migrations.finalize
              end

              # iterate through this sections methods in order and look
              # for any that match the migrations we have
              section[:methods].each do |method_name|
                # if we have a migration which matches one of the methods in this section
                unless migrations[method_name].nil?
                  schema_migrations.add_content schema_name, table_name, :comment, nil, section[:header_comment]
                  migrations[method_name].each do |migration|
                    schema_migrations.add_content schema_name, table_name, method_name, migration[:object_name], migration[:content]
                  end
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

      def add_migration schema_name, table_name, migration_method, object_name, migration
        raise ExpectedSymbolError, "Expected schema_name to be a symbol, got #{schema_name}" unless schema_name.is_a?(Symbol)
        raise ExpectedSymbolError, "Expected table_name to be a symbol, got #{table_name}" unless schema_name.is_a?(Symbol)

        unless supported_migration_method? migration_method
          raise UnexpectedMigrationMethodNameError, "Expected migration_method to be a valid migrator method, got `#{migration_method}`"
        end

        fixed_indentation_migration = fix_indentation migration
        @migrations[schema_name] ||= {}
        # note, table_name can be nil, which is OK because nil is a valid
        # key and we do want to group them all together
        @migrations[schema_name][table_name] ||= {}
        @migrations[schema_name][table_name][migration_method] ||= []
        @migrations[schema_name][table_name][migration_method] << {
          object_name:,
          content: fixed_indentation_migration
        }
        # return the newly created migration
        fixed_indentation_migration
      end
    end
  end
end
