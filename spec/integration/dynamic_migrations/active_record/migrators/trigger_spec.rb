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
          "'" + s.gsub("/", "//").gsub("'", "''") + "'"
        end
      end
    }

    let(:migration) { migration_class.new }

    describe :Trigger do
      describe "once the schema_name has been set on the migration class" do
        before(:each) do
          migration_class.set_schema_name :my_schema
        end

        describe :add_trigger do
          it "generates the expected sql for a basic trigger" do
            migration.add_trigger(:my_table, name: :my_trigger, action_timing: :before, event_manipulation: :insert, action_orientation: :row, function_schema_name: :my_schema, function_name: :my_function)

            expect(migration).to executed_sql <<~SQL
              CREATE TRIGGER my_trigger
                BEFORE INSERT ON my_schema.my_table
                  FOR EACH row
                    EXECUTE FUNCTION my_schema.my_function();
            SQL
          end

          it "generates the expected sql for a trigger which includes a condition" do
            migration.add_trigger(:my_table, name: :my_trigger, action_timing: :before, event_manipulation: :insert, action_orientation: :row, function_schema_name: :my_schema, function_name: :my_function, action_condition: "NEW.my_column != 0")

            expect(migration).to executed_sql <<~SQL
              CREATE TRIGGER my_trigger
                BEFORE INSERT ON my_schema.my_table
                  FOR EACH row
                    WHEN (NEW.my_column != 0)
                    EXECUTE FUNCTION my_schema.my_function();
            SQL
          end

          it "generates the expected sql for a trigger which includes parameters" do
            migration.add_trigger(:my_table, name: :my_trigger, parameters: ["true"], action_timing: :before, event_manipulation: :insert, action_orientation: :row, function_schema_name: :my_schema, function_name: :my_function, action_condition: "NEW.my_column != 0")

            expect(migration).to executed_sql <<~SQL
              CREATE TRIGGER my_trigger
                BEFORE INSERT ON my_schema.my_table
                  FOR EACH row
                    WHEN (NEW.my_column != 0)
                    EXECUTE FUNCTION my_schema.my_function('true');
            SQL
          end
        end

        describe :remove_trigger do
          it "generates the expected sql" do
            migration.remove_trigger(:my_table, :my_trigger)

            expect(migration).to executed_sql <<~SQL
              DROP TRIGGER my_trigger ON my_schema.my_table;
            SQL
          end
        end

        describe :set_trigger_comment do
          it "generates the expected sql" do
            migration.set_trigger_comment(:my_table, :my_trigger, "my comment")

            expect(migration).to executed_sql <<~SQL
              COMMENT ON TRIGGER my_trigger ON my_schema.my_table IS 'my comment';
            SQL
          end
        end

        describe :remove_trigger_comment do
          it "generates the expected sql" do
            migration.remove_trigger_comment(:my_table, :my_trigger)

            expect(migration).to executed_sql <<~SQL
              COMMENT ON TRIGGER my_trigger ON my_schema.my_table IS NULL;
            SQL
          end
        end
      end
    end
  end
end
