module DynamicMigrations
  module Postgres
    class Generator
      module Schema
        def create_schema schema, code_comment = nil
          # no table or schema name for this fragment (it is executed at the database level)
          add_fragment migration_method: :create_schema,
            object: schema,
            code_comment: code_comment,
            migration: <<~RUBY
              create_schema :#{schema.name}
            RUBY
        end

        def drop_schema schema, code_comment = nil
          # no table or schema name for this fragment (it is executed at the database level)
          add_fragment migration_method: :drop_schema,
            object: schema,
            code_comment: code_comment,
            migration: <<~RUBY
              drop_schema :#{schema.name}
            RUBY
        end
      end
    end
  end
end
