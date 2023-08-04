module DynamicMigrations
  class Generator
    module Schema
      def create_schema schema
        add_migration schema.name, nil, "create_#{schema.name}_schema", <<~RUBY
          create_schema :#{schema.name}
        RUBY
      end

      def drop_schema schema
        add_migration schema.name, nil, "create_#{schema.name}_schema", <<~RUBY
          drop_schema :#{schema.name}
        RUBY
      end
    end
  end
end
