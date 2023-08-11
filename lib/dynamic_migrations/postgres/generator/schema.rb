module DynamicMigrations
  module Postgres
    class Generator
      module Schema
        def create_schema schema, code_comment = nil
          add_migration schema.name, nil, :create_schema, schema.name, code_comment, <<~RUBY
            create_schema :#{schema.name}
          RUBY
        end

        def drop_schema schema, code_comment = nil
          add_migration schema.name, nil, :drop_schema, schema.name, code_comment, <<~RUBY
            drop_schema :#{schema.name}
          RUBY
        end
      end
    end
  end
end
