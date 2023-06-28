# frozen_string_literal: true

require "pg"

require "dynamic_migrations/version"

require "dynamic_migrations/postgres/server/database/schema/table/loaded_columns"
require "dynamic_migrations/postgres/server/database/schema/table/configured_columns"
require "dynamic_migrations/postgres/server/database/schema/table/column"
require "dynamic_migrations/postgres/server/database/schema/table"
require "dynamic_migrations/postgres/server/database/schema/loaded_tables"
require "dynamic_migrations/postgres/server/database/schema/configured_tables"
require "dynamic_migrations/postgres/server/database/schema"
require "dynamic_migrations/postgres/server/database/connection"
require "dynamic_migrations/postgres/server/database/loaded_schemas"
require "dynamic_migrations/postgres/server/database/configured_schemas"
require "dynamic_migrations/postgres/server/database"
require "dynamic_migrations/postgres/server"
require "dynamic_migrations/postgres/connections"
require "dynamic_migrations/postgres"

module DynamicMigrations
  class Error < StandardError
  end
end
