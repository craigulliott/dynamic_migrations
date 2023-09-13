module DynamicMigrations
  module Postgres
    class Generator
      module Extension
        def enable_extension extension_name, code_comment = nil
          # no table or schema name for this fragment (it is executed at the database level)
          add_fragment migration_method: :enable_extension,
            object: extension_name,
            code_comment: code_comment,
            migration: <<~RUBY
              enable_extension "#{extension_name}"
            RUBY
        end

        def disable_extension extension_name, code_comment = nil
          # no table or schema name for this fragment (it is executed at the database level)
          add_fragment migration_method: :disable_extension,
            object: extension_name,
            code_comment: code_comment,
            migration: <<~RUBY
              disable_extension "#{extension_name}"
            RUBY
        end
      end
    end
  end
end
