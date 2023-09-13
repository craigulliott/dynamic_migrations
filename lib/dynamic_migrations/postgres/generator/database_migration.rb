module DynamicMigrations
  module Postgres
    class Generator
      class DatabaseMigration < Migration
        # these sections are in order for which they will appear in a migration,
        # note that removals come before additions, and that the order here optomizes
        # for dependencies (i.e. columns have to be created before indexes are added and
        # triggers are removed before functions are dropped)
        add_structure_template [:disable_extension], "Drop Extension"
        add_structure_template [:enable_extension], "Create Extension"
        add_structure_template [:drop_schema], "Drop this schema"
        add_structure_template [:create_schema], "Create this schema"
      end
    end
  end
end
