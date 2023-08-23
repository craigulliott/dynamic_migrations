module DynamicMigrations
  module Postgres
    class Generator
      module Extension
        def create_extension extension_name, code_comment = nil
          # no table or schema name for this fragment (it is executed at the database level)
          add_fragment migration_method: :create_extension,
            object: extension_name,
            code_comment: code_comment,
            migration: <<~RUBY
              create_extension :#{extension_name}
            RUBY
        end

        def drop_extension extension_name, code_comment = nil
          # no table or schema name for this fragment (it is executed at the database level)
          add_fragment migration_method: :drop_extension,
            object: extension_name,
            code_comment: code_comment,
            migration: <<~RUBY
              drop_extension :#{extension_name}
            RUBY
        end
      end
    end
  end
end
