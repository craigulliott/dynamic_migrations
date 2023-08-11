module DynamicMigrations
  module Postgres
    class Generator
      class Fragment
        attr_reader :object_name
        attr_reader :code_comment

        def initialize object_name, code_comment, content
          @object_name = object_name
          @code_comment = code_comment
          @content = content
        end

        def to_s
          strings = []
          comment = @code_comment
          unless comment.nil?
            strings << "# " + comment.split("\n").join("\n# ")
          end
          strings << @content
          strings.join("\n").strip
        end

        def has_code_comment?
          !@code_comment.nil?
        end
      end
    end
  end
end
