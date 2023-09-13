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

    describe :Column do
      describe "once the schema_name has been set on the migration class" do
        before(:each) do
          migration_class.set_schema_name :my_schema
        end

        describe :set_column_comment do
          it "generates the expected sql" do
            migration.set_column_comment(:my_table, :my_column, "my comment")

            expect(migration).to executed_sql <<~SQL
              COMMENT ON COLUMN my_schema.my_table.my_column IS 'my comment';
            SQL
          end
        end

        describe :remove_column_comment do
          it "generates the expected sql" do
            migration.remove_column_comment(:my_table, :my_column)

            expect(migration).to executed_sql <<~SQL
              COMMENT ON COLUMN my_schema.my_table.my_column IS NULL;
            SQL
          end
        end
      end
    end
  end
end
