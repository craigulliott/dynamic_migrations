module DynamicMigrations
  module Postgres
    class Generator
      module Extension
        def enable_extension extension_name, code_comment = nil
          # no table or schema name for this fragment (it is executed at the database level)
          add_fragment migration_method: :enable_extension,
            # some extensions have hyphens in them, so coerce the name to underscores
            # because the object name is used in the migration class name
            object: extension_name.to_s.tr("-", "_").to_sym,
            code_comment: code_comment,
            migration: <<~RUBY
              enable_extension "#{extension_name}"
            RUBY
        end

        def disable_extension extension_name, code_comment = nil
          # no table or schema name for this fragment (it is executed at the database level)
          add_fragment migration_method: :disable_extension,
            # some extensions have hyphens in them, so coerce the name to underscores
            # because the object name is used in the migration class name
            object: extension_name.to_s.tr("-", "_").to_sym,
            code_comment: code_comment,
            migration: <<~RUBY
              disable_extension "#{extension_name}"
            RUBY
        end
      end
    end
  end
end
