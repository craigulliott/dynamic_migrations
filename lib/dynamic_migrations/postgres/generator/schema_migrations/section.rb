module DynamicMigrations
  module Postgres
    class Generator
      class SchemaMigrations
        class Section
          attr_reader :schema_name
          attr_reader :table_name
          attr_reader :content_type
          attr_reader :fragment

          def initialize schema_name, table_name, content_type, fragment
            @schema_name = schema_name
            @table_name = table_name
            @content_type = content_type
            @fragment = fragment
          end

          def object_name
            @fragment.object_name
          end

          def to_s
            @fragment.to_s
          end

          def is_comment?
            content_type? :comment
          end

          def content_type? content_type
            @content_type == content_type
          end
        end
      end
    end
  end
end
