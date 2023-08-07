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

    describe :CheckConstraint do
      describe "once the schema_name has been set on the module" do
        before(:each) do
          DynamicMigrations::ActiveRecord::Migrators.set_schema_name :my_schema
        end

        after(:each) do
          DynamicMigrations::ActiveRecord::Migrators.clear_schema_name
        end

        describe :add_check_constraint do
          it "generates the expected sql for a simple check constraint" do
            migration.add_check_constraint(:my_table, "my_column > 0", name: :my_check_constraint)

            expect(migration).to executed_sql <<~SQL
              ALTER TABLE my_table
                ADD CONSTRAINT my_check_constraint
                  CHECK (my_column > 0)
                  NOT DEFERRABLE;
            SQL
          end

          it "generates the expected sql for an initially_deferred simple check constraint" do
            migration.add_check_constraint(:my_table, "my_column > 0", name: :my_check_constraint, initially_deferred: true, deferrable: true)

            expect(migration).to executed_sql <<~SQL
              ALTER TABLE my_table
                ADD CONSTRAINT my_check_constraint
                  CHECK (my_column > 0)
                  DEFERRABLE INITIALLY DEFERRED;
            SQL
          end

          it "generates the expected sql for an initially_deferred simple check constraint with a comment" do
            migration.add_check_constraint(:my_table, "my_column > 0", name: :my_check_constraint, initially_deferred: true, deferrable: true, comment: "my comment")
            expected_sql = []
            expected_sql << <<~SQL
              ALTER TABLE my_table
                ADD CONSTRAINT my_check_constraint
                  CHECK (my_column > 0)
                  DEFERRABLE INITIALLY DEFERRED;
            SQL
            expected_sql << <<~SQL
              COMMENT ON CONSTRAINT my_check_constraint ON my_schema.my_table IS 'my comment';
            SQL
            expect(migration).to executed_sql expected_sql
          end

          it "raises an error if an invalid combination of initially_deferred and deferrable is provided" do
            expect {
              migration.add_check_constraint(:my_table, "my_column > 0", name: :my_check_constraint, initially_deferred: true, deferrable: false)
            }.to raise_error DynamicMigrations::ActiveRecord::Migrators::DeferrableOptionsError
          end
        end
      end
    end
  end
end
