# frozen_string_literal: true

require "pg"

require "dynamic_migrations/version"
require "dynamic_migrations/invalid_source_error"
require "dynamic_migrations/expected_symbol_error"
require "dynamic_migrations/expected_string_error"
require "dynamic_migrations/expected_integer_error"

require "dynamic_migrations/postgres/server/database/connection"
require "dynamic_migrations/postgres/server/database/structure_loader"
require "dynamic_migrations/postgres/server/database/constraints_loader"
require "dynamic_migrations/postgres/server/database/loaded_schemas_builder"
require "dynamic_migrations/postgres/server/database/differences"
require "dynamic_migrations/postgres/server/database/loaded_schemas"
require "dynamic_migrations/postgres/server/database/configured_schemas"
require "dynamic_migrations/postgres/server/database"
require "dynamic_migrations/postgres/server/database/source"
require "dynamic_migrations/postgres/server/database/schema"
require "dynamic_migrations/postgres/server/database/schema/table"
require "dynamic_migrations/postgres/server/database/schema/table/column"
require "dynamic_migrations/postgres/server/database/schema/table/constraint"

require "dynamic_migrations/postgres/server"
require "dynamic_migrations/postgres/connections"
require "dynamic_migrations/postgres/data_types"

module DynamicMigrations
  class Error < StandardError
  end
end
