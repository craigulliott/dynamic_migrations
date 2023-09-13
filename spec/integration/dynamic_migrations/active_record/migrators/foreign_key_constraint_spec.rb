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

    describe :ForeignKeyConstraint do
      describe "once the schema_name has been set on the migration class" do
        before(:each) do
          migration_class.set_schema_name :my_schema
        end

        describe :add_foreign_key do
          it "generates the expected sql for a basic foreign key constraint" do
            migration.add_foreign_key(:my_table, :my_column, :foreign_schema, :foreign_table, :foreign_column, name: :my_foreign_key)

            expect(migration).to executed_sql <<~SQL
              ALTER TABLE my_table
                ADD CONSTRAINT my_foreign_key
                  FOREIGN KEY (my_column)
                    REFERENCES  foreign_schema.foreign_table (foreign_column)
                ON DELETE NO ACTION
                ON UPDATE NO ACTION
                NOT DEFERRABLE;
            SQL
          end

          it "generates the expected sql for a composite foreign key constraint" do
            migration.add_foreign_key(:my_table, [:my_column, :my_other_column], :foreign_schema, :foreign_table, [:foreign_column, :other_foreign_column], name: :my_foreign_key)

            expect(migration).to executed_sql <<~SQL
              ALTER TABLE my_table
                ADD CONSTRAINT my_foreign_key
                  FOREIGN KEY (my_column, my_other_column)
                    REFERENCES  foreign_schema.foreign_table (foreign_column, other_foreign_column)
                ON DELETE NO ACTION
                ON UPDATE NO ACTION
                NOT DEFERRABLE;
            SQL
          end

          it "raises an error if an invalid combination of initially_deferred and deferrable is provided" do
            expect {
              migration.add_foreign_key(:my_table, [:my_column, :my_other_column], :foreign_schema, :foreign_table, [:foreign_column, :other_foreign_column], name: :my_foreign_key, initially_deferred: true, deferrable: false)
            }.to raise_error DynamicMigrations::ActiveRecord::Migrators::DeferrableOptionsError
          end
        end

        describe :remove_foreign_key do
          it "generates the expected sql" do
            migration.remove_foreign_key(:my_table, :my_foreign_key_constraint)

            expect(migration).to executed_sql <<~SQL
              ALTER TABLE my_table
                DROP CONSTRAINT my_foreign_key_constraint;
            SQL
          end
        end

        describe :set_foreign_key_comment do
          it "generates the expected sql" do
            migration.set_foreign_key_comment(:my_table, :my_foreign_key_constraint, "my comment")

            expect(migration).to executed_sql <<~SQL
              COMMENT ON CONSTRAINT my_foreign_key_constraint ON my_schema.my_table IS 'my comment';
            SQL
          end
        end

        describe :remove_foreign_key_comment do
          it "generates the expected sql" do
            migration.remove_foreign_key_comment(:my_table, :my_foreign_key_constraint)

            expect(migration).to executed_sql <<~SQL
              COMMENT ON CONSTRAINT my_foreign_key_constraint ON my_schema.my_table IS NULL;
            SQL
          end
        end
      end
    end
  end
end
