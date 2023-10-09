module DynamicMigrations
  module Postgres
    class Generator
      class ExpectedSymbolError < StandardError
      end

      class DeferrableOptionsError < StandardError
      end

      class MissingDescriptionError < StandardError
      end

      class NoDifferenceError < StandardError
      end

      class TableMigrationNotFound < StandardError
      end

      class UnprocessableFragmentError < StandardError
      end

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
      include Enum
      include Extension

      def initialize
        @fragments = []
        @logger = Logging.logger[self]
      end

      # builds the final migrations
      def migrations
        log.info "Generating migrations"

        # a hash to hold the generated migrations orgnized by their schema and table
        # this makes it easier and faster to work with them within this method
        database_migrations = {}
        # the database_specific_migrations are for migrations which dont belong
        # within a specific schema, they are important enough that we have a
        # dedicated migration for each one
        database_specific_migrations = []

        # Process each fragment, and organize them into migrations. We create a shared
        # Migration for each table, and a single shared migration for any schema migrations
        # which do not relate to a table.
        log.info "  Organizing migration fragments"
        @fragments.each do |fragment|
          # The first time this schema is encountered we create an object to hold the migrations
          # and organize the different migrations.
          schema_migrations = database_migrations[fragment.schema_name] ||= {
            schema_migration: nil,
            table_migrations: {},
            # this array will hold any migrations which were created by splitting apart table
            # migrations to resolve circular dependencies
            additional_migrations: []
          }
          schema_name = fragment.schema_name
          table_name = fragment.table_name
          # If we have a table name, then add the migration fragment to a
          # TableMigration which holds all of the migrations for this table
          if table_name && schema_name
            table_migration = schema_migrations[:table_migrations][table_name] ||= TableMigration.new(schema_name, table_name)
            table_migration.add_fragment fragment

          # migration fragments which do have a schema, but do not belong to a specific table are added
          # to a dedicated SchemaMigration object
          elsif schema_name && table_name.nil?
            schema_migration = schema_migrations[:schema_migration] ||= SchemaMigration.new(schema_name)
            schema_migration.add_fragment fragment

          # migrations with no schema or table, are added to a database
          # migration (these are really just creating/dropping schemas and extensions)
          elsif schema_name.nil? && table_name.nil?
            database_specific_migration = DatabaseMigration.new
            database_specific_migration.add_fragment(fragment)
            database_specific_migrations << database_specific_migration

          else
            raise UnprocessableFragmentError
          end
        end

        # Convert the hash of migrations into an array of migrations, this is
        # passed to the `circular_dependency?` method below, and any new migrations
        # required to resolve circular dependencies will be added to this array
        all_table_migrations = database_migrations.values.map { |m| m[:table_migrations].values }.flatten

        # For each migration, we recursively traverse the dependency graph to detect and handle circular
        # dependencies.
        #
        # Initially, all the fragments which pertain to a particular table are grouped together in
        # the same migration. If a circular dependency between migrations is detected, then we simply
        # pop the offending migration fragments out of the dedicated table migration and into a new
        # migration. This allows the migration to be processed later, and resolves the circular dependency.
        log.info "  Resolving circular dependencies between migrations"
        completed_table_migrations = []
        all_table_migrations.each do |table_migration|
          # skip it if it's already been processed
          next if completed_table_migrations.include? table_migration
          # recusrsively resolve the circular dependencies for this migration
          resolve_circular_dependencies table_migration, all_table_migrations, database_migrations, completed_table_migrations
        end

        # Prepare a dependency sorter, this is used to sort the migrations via rubys included Tsort module
        # The object used to sort the migrations is extended from a hash, and takes the form:
        # {
        #   # every migration exists as a key, and its corresponding array is all the
        #   # migrations which it depends on
        #   migration1 => [migration2, migration3],
        #   migration3 => [migration2]
        # }
        log.info "  Preparing migrations for sorting"
        dependency_sorter = MigrationDependencySorter.new
        database_migrations.each do |schema_name, schema_migrations|
          if schema_migrations[:schema_migration]
            # the schema migration never has any dependencies
            dependency_sorter[schema_migrations[:schema_migration]] = []
          end
          # add each table migration, and its dependencies
          schema_migrations[:table_migrations].values.each do |table_migration|
            deps = dependency_sorter[table_migration] = []
            # if there is a schema migration, then it should always come first
            # so make the table migration depend on it
            deps << schema_migrations[:schema_migration] if schema_migrations[:schema_migration]
            # if the table migration has any dependencies on other tables, then add them
            table_migration.table_dependencies.each do |dependency|
              # find the migration which matches the dependency
              dependent_migration = database_migrations[dependency[:schema_name]] && database_migrations[dependency[:schema_name]][:table_migrations][dependency[:table_name]]
              # if the table migration is not found, then it's safe to assume the table was created
              # by an earlier set of migrations
              unless dependent_migration.nil?
                # add the dependent migration to the list of dependencies
                deps << dependent_migration
              end
            end
            # if the table migration has any dependencies on functions or enums, then add them
            (table_migration.function_dependencies + table_migration.enum_dependencies).each do |dependency|
              # functions are always added to a schema specific migration, if it does not exist then
              # we can assume the function was added in a previous set of migrations
              if (dependencies_schema_migration = database_migrations[dependency[:schema_name]] && database_migrations[dependency[:schema_name]][:schema_migration])
                deps << dependencies_schema_migration
              end
            end
          end
          # add each additional migration, and its dependencies
          schema_migrations[:additional_migrations].each do |additional_migration|
            deps = dependency_sorter[additional_migration] = []
            # if there is a schema migration, then it should always come first
            # so make the table migration depend on it
            deps << schema_migrations[:schema_migration] if schema_migrations[:schema_migration]

            # additional migrations are always dependent on the table migration which they came from
            table_migration = schema_migrations[:table_migrations][additional_migration.table_name]
            # if the table migration is not found, then it's safe to assume the table was created
            # by an earlier set of migrations
            unless table_migration.nil?
              deps << table_migration

              # if the table migration has any dependencies on functions or enums, then add them
              (table_migration.function_dependencies + table_migration.enum_dependencies).each do |dependency|
                # functions are always added to a schema specific migration, if it does not exist then
                # we can assume the function was added in a previous set of migrations
                if (dependencies_schema_migration = database_migrations[dependency[:schema_name]] && database_migrations[dependency[:schema_name]][:schema_migration])
                  deps << dependencies_schema_migration
                end
              end
            end

            # if the additional_migration has any dependencies on other tables, then add them too
            additional_migration.table_dependencies.each do |dependency|
              # find the table migration which matches the dependency
              dependent_migration = database_migrations[dependency[:schema_name]] && database_migrations[dependency[:schema_name]][:table_migrations][dependency[:table_name]]
              # if the table migration is not found, then it's safe to assume the table was created
              # by an earlier set of migrations
              unless dependent_migration.nil?
                deps << dependent_migration
              end
            end
          end
        end

        # sort the migrations so that they are executed in the correct order
        # the order is determined by their dependencies
        log.info "  Sorting migrations based on their dependencies"
        final_migrations = dependency_sorter.tsort

        # if any database only migrations exist, then add them to the front of the array here
        if database_specific_migrations.any?
          final_migrations = database_specific_migrations + final_migrations
        end

        # return the final migrations in the expected format
        final_migrations.map do |migration|
          {
            schema_name: migration.schema_name,
            name: migration.name,
            content: migration.content
          }
        end
      end

      private

      # Initially, all the fragments which pertain to a particular table are grouped together in
      # the same migration. If a circular dependency between migrations is detected, then we simply
      # pop the offending migration fragments out of the dedicated table migration and into a new
      # migration. This allows the migration to be processed later, and resolves the circular dependency.
      #
      # Note, "table migrations" are the default migrations which initially contain all the fragments for
      # a particular table.
      #
      # `table_migration` is the current migration which is being processed
      # `all_table_migrations` is all the table migrations in this current set of migrations
      # `database_migrations` is a hash of all the migrations, organized by schema and table, we need this
      # object so that we can add any new migrations which are created to resolve circular dependencies
      # `completed_table_migrations` is an array of all the table migrations which have already been
      # processed, we use this for performance reasons, so that we dont process the same migration twice
      # `stack` is an array of all the migrations which have been processed so far in this current recursive
      # path, this is used to detect circular dependencies.
      def resolve_circular_dependencies table_migration, all_table_migrations, database_migrations, completed_table_migrations, stack = []
        # process all the current dependencies for this migration
        # each dependency is a hash, with the schema_name and table_name
        table_migration.table_dependencies.each do |dependency|
          # look in the list of all table migrations and try and find the migration which
          # matches the current dependency, note that this migration may not exist because
          # the table could have been created in a previous set of migrations
          if (next_table_migration = all_table_migrations.find { |m| m.schema_name == dependency[:schema_name] && m.table_name == dependency[:table_name] })
            # if this migration has already been processed, then we can skip it
            next if completed_table_migrations.include? next_table_migration

            key = "#{next_table_migration.schema_name}.#{next_table_migration.table_name}"
            # if this migration already exists in the stack, then we have a circular dependency
            if stack.include? key
              log.info "    Resolving circular dependency for #{table_migration.schema_name}.#{table_migration.table_name} -> #{next_table_migration.schema_name}.#{next_table_migration.table_name}"

              # if the number of fragments in the table migration is equal to the number of fragments
              # which would be removed, then there is no need to split the migration
              next if table_migration.fragments.count == table_migration.fragments_with_table_dependency_count(next_table_migration.schema_name, next_table_migration.table_name)

              # remove the fragments which are causing the circular dependency
              removed_fragments = table_migration.extract_fragments_with_table_dependency next_table_migration.schema_name, next_table_migration.table_name

              # create a new table migration for these fragments
              new_migration = TableMigration.new(table_migration.schema_name, table_migration.table_name)

              # place these fragments in their own migration
              removed_fragments.each do |removed_fragment|
                new_migration.add_fragment removed_fragment
              end

              # add the new migration to the list of additional (not standard table migrations) for
              # this schema
              database_migrations[table_migration.schema_name][:additional_migrations] << new_migration

              # continue to the next dependency
              next
            end

            # create a new stack, so that each recursive call has it's own copy
            new_stack = stack + [key]

            # recursively move on to the next migration
            resolve_circular_dependencies next_table_migration, all_table_migrations, database_migrations, completed_table_migrations, new_stack

            # when the code reaches this point, we have completed the recursive traversal of
            # all the dependencies originating from next_table_migration, so we can add it to
            # the array of completed migrations, note that this array is shared across all
            # recursive calls, so that we can keep track of which migrations have been processed
            completed_table_migrations << next_table_migration
          end
        end
      end

      # tsort_each_node is used to iterate for all nodes over a graph.
      def tsort_each_node(&block)
        @fragments.each(&block)
      end

      # tsort_each_child is used to iterate for child nodes of a given node.
      def tsort_each_child(node, &block)
        @dep[node].each(&block)
      end

      # This method is called from within the various modules which are included to this class.
      # It locally stores all the fragments which will later be organized into different migrations.
      def add_fragment migration_method:, object:, migration:, schema: nil, table: nil, code_comment: nil, dependent_table: nil, dependent_function: nil, dependent_enum: nil
        # Remove any empty lines and whitespace from the beginning or the end of the migration
        final_migration = trim_lines migration
        fragment = Fragment.new(schema&.name, table&.name, migration_method, object.name, code_comment, final_migration)

        if dependent_table
          fragment.set_dependent_table dependent_table.schema.name, dependent_table.name
        end

        if dependent_function
          fragment.set_dependent_function dependent_function.schema.name, dependent_function.name
        end

        if dependent_enum
          fragment.set_dependent_enum dependent_enum.schema.name, dependent_enum.name
        end

        # add this fragment to the list
        @fragments << fragment

        # return the newly created migration fragment
        fragment
      end

      def indent multi_line_string, levels = 1
        spaces = "  " * levels
        multi_line_string.gsub("\n", "\n#{spaces}")
      end

      def trim_lines string
        string.split("\n").map(&:rstrip).join("\n")
      end

      def log
        @logger
      end
    end
  end
end
