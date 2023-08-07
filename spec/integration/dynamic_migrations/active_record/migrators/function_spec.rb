# frozen_string_literal: true

RSpec.describe DynamicMigrations::ActiveRecord::Migrators do
  describe "for a class which includes the Migrators Module" do
    let(:migration_class) {
      Class.new do
        include DynamicMigrations::ActiveRecord::Migrators

        # capture the execute statements so we can validate the SQL
        # created rather than actually executing it.
        attr_reader :sqls
        def execute sql
          @sqls ||= []
          @sqls << sql
        end

        # stub out the quote method so we can validate the SQL
        # this is usually handled by the connection adapter
        def quote s
          s.gsub("/", "//").gsub("'", "''")
        end
      end
    }

    let(:migration) { migration_class.new }

    describe :Function do
      describe "once the schema_name has been set on the module" do
        before(:each) do
          DynamicMigrations::ActiveRecord::Migrators.set_schema_name :my_schema
        end

        after(:each) do
          DynamicMigrations::ActiveRecord::Migrators.clear_schema_name
        end

        describe :create_function do
          it "generates the expected sql" do
            migration.create_function(:my_table, :my_function, "NEW.column = 0")

            expect(migration).to executed_sql <<~SQL
              CREATE FUNCTION my_schema.my_function() returns trigger language plpgsql AS
              $$BEGIN NEW.column = 0;
              RETURN NEW;
              END$$;
            SQL
          end
        end

        describe :drop_function do
          it "generates the expected sql" do
            migration.drop_function(:my_function)

            expect(migration).to executed_sql <<~SQL
              DROP FUNCTION my_schema.my_function();
            SQL
          end
        end

        describe :set_function_comment do
          it "generates the expected sql" do
            migration.set_function_comment(:my_function, "my comment")

            expect(migration).to executed_sql <<~SQL
              COMMENT ON FUNCTION my_schema.my_function IS 'my comment';
            SQL
          end
        end

        describe :remove_function_comment do
          it "generates the expected sql" do
            migration.remove_function_comment(:my_function)

            expect(migration).to executed_sql <<~SQL
              COMMENT ON FUNCTION my_schema.my_function IS null;
            SQL
          end
        end
      end
    end
  end
end
