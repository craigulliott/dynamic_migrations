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

    describe :Enum do
      describe "once the schema_name has been set on the migration class" do
        before(:each) do
          migration_class.set_schema_name :my_schema
        end

        describe :create_enum do
          it "generates the expected sql" do
            migration.create_enum :my_enum, [
              :foo,
              :bar
            ]

            expect(migration).to executed_sql <<~SQL
              CREATE TYPE my_schema.my_enum as ENUM ('foo','bar');
            SQL
          end
        end

        describe :add_enum_values do
          it "generates the expected sql" do
            migration.add_enum_values :my_enum, [
              :baz,
              :foz
            ]

            expect(migration).to executed_sql <<~SQL
              ALTER TYPE my_schema.my_enum ADD ATTRIBUTE 'baz';
              ALTER TYPE my_schema.my_enum ADD ATTRIBUTE 'foz';
            SQL
          end
        end

        describe :drop_enum do
          it "generates the expected sql" do
            migration.drop_enum(:my_enum)

            expect(migration).to executed_sql <<~SQL
              DROP TYPE my_schema.my_enum;
            SQL
          end
        end

        describe :set_enum_comment do
          it "generates the expected sql" do
            migration.set_enum_comment(:my_enum, "my comment")

            expect(migration).to executed_sql <<~SQL
              COMMENT ON TYPE my_schema.my_enum IS 'my comment';
            SQL
          end
        end

        describe :remove_enum_comment do
          it "generates the expected sql" do
            migration.remove_enum_comment(:my_enum)

            expect(migration).to executed_sql <<~SQL
              COMMENT ON TYPE my_schema.my_enum IS null;
            SQL
          end
        end
      end
    end
  end
end
