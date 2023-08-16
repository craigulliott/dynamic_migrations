# TSort is a module included in the Ruby standard library for
# executing topological sorts. We use it here to sort the migration
# fragments so that they are executed in the correct order (i.e. tables
# which have foreign keys are created after the tables they point to).
require "tsort"

module DynamicMigrations
  module Postgres
    class Generator
      class MigrationDependencySorter < Hash
        include TSort

        alias_method :tsort_each_node, :each_key

        def tsort_each_child(node, &block)
          fetch(node).each(&block)
        end
      end
    end
  end
end
