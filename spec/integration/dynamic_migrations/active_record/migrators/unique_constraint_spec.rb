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

    describe :UniqueConstraint do
      describe "once the schema_name has been set on the module" do
        before(:each) do
          DynamicMigrations::ActiveRecord::Migrators.set_schema_name :my_schema
        end

        after(:each) do
          DynamicMigrations::ActiveRecord::Migrators.clear_schema_name
        end

        describe :add_unique_constraint do
          it "generates the expected sql" do
            migration.add_unique_constraint(:my_table, [:my_column], name: :my_unique_constraint)

            expect(migration).to executed_sql <<~SQL
              ALTER TABLE my_table
                ADD CONSTRAINT my_unique_constraint
                  UNIQUE (my_column)
                  NOT DEFERRABLE;
            SQL
          end
        end

        describe :remove_unique_constraint do
          it "generates the expected sql" do
            migration.remove_unique_constraint(:my_table, :my_unique_constraint)

            expect(migration).to executed_sql <<~SQL
              ALTER TABLE my_table
                DROP CONSTRAINT my_unique_constraint;
            SQL
          end
        end

        describe :set_unique_constraint_comment do
          it "generates the expected sql" do
            migration.set_unique_constraint_comment(:my_table, :my_unique_constraint, "my comment")

            expect(migration).to executed_sql <<~SQL
              COMMENT ON CONSTRAINT my_unique_constraint ON my_schema.my_table IS 'my comment';
            SQL
          end
        end

        describe :remove_unique_constraint_comment do
          it "generates the expected sql" do
            migration.remove_unique_constraint_comment(:my_table, :my_unique_constraint)

            expect(migration).to executed_sql <<~SQL
              COMMENT ON CONSTRAINT my_unique_constraint ON my_schema.my_table IS NULL;
            SQL
          end
        end
      end
    end
  end
end
