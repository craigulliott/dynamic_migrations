module DynamicMigrations
  module ActiveRecord
    module Migrators
      module Enum
        # create a postgres enum
        def create_enum enum_name, values
          # schema_name was not provided to this method, it comes from the migration class
          execute <<~SQL
            CREATE TYPE #{schema_name}.#{enum_name} as ENUM ('#{values.join("','")}');
          SQL
        end

        # add vaues to a given enum
        def add_enum_values enum_name, values
          sqls = values.map do |value|
            "ALTER TYPE #{schema_name}.#{enum_name} ADD ATTRIBUTE '#{value}';"
          end
          execute sqls.join("\n")
        end

        # remove a enum from the schema
        def drop_enum enum_name
          execute <<~SQL
            DROP TYPE #{schema_name}.#{enum_name};
          SQL
        end

        # add a comment to a enum
        def set_enum_comment enum_name, comment
          execute <<~SQL
            COMMENT ON TYPE #{schema_name}.#{enum_name} IS '#{quote comment}';
          SQL
        end

        # remove the comment from a enum
        def remove_enum_comment enum_name
          execute <<~SQL
            COMMENT ON TYPE #{schema_name}.#{enum_name} IS null;
          SQL
        end
      end
    end
  end
end
