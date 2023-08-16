module DynamicMigrations
  module Postgres
    class Generator
      module Schema
        def create_schema schema, code_comment = nil
          add_fragment schema: schema,
            migration_method: :create_schema,
            object: schema,
            code_comment: code_comment,
            migration: <<~RUBY
              create_schema :#{schema.name}
            RUBY
        end

        def drop_schema schema, code_comment = nil
          add_fragment schema: schema,
            migration_method: :drop_schema,
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
