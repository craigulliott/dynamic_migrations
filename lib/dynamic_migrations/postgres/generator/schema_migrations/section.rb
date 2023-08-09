module DynamicMigrations
  module Postgres
    class Generator
      class SchemaMigrations
        warn "not tested"
        class Section
          attr_reader :schema_name
          attr_reader :table_name
          attr_reader :content_type
          attr_reader :object_name
          attr_reader :content

          def initialize schema_name, table_name, content_type, object_name, content
            @schema_name = schema_name
            @table_name = table_name
            @content_type = content_type
            @object_name = object_name
            @content = content
          end

          def content_type? content_type
            @content_type == content_type
          end
        end
      end
    end
  end
end
