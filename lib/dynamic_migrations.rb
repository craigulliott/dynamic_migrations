# frozen_string_literal: true

require "pg"

require "dynamic_migrations/version"
require "dynamic_migrations/invalid_source_error"
require "dynamic_migrations/expected_symbol_error"

require "dynamic_migrations/postgres/server/database/connection"
require "dynamic_migrations/postgres/server/database/loader"
require "dynamic_migrations/postgres/server/database/differences"
require "dynamic_migrations/postgres/server/database/data_type"
require "dynamic_migrations/postgres/server/database/loaded_schemas"
require "dynamic_migrations/postgres/server/database/configured_schemas"
require "dynamic_migrations/postgres/server/database"
require "dynamic_migrations/postgres/server/database/source"
require "dynamic_migrations/postgres/server/database/schema"
require "dynamic_migrations/postgres/server/database/schema/table"
require "dynamic_migrations/postgres/server/database/schema/table/column"

require "dynamic_migrations/postgres/server"
require "dynamic_migrations/postgres/connections"

module DynamicMigrations
  class Error < StandardError
  end
end
