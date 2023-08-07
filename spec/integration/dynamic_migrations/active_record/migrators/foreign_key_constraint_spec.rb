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
      describe "once the schema_name has been set on the module" do
        before(:each) do
          DynamicMigrations::ActiveRecord::Migrators.set_schema_name :my_schema
        end

        after(:each) do
          DynamicMigrations::ActiveRecord::Migrators.clear_schema_name
        end

        describe :add_foreign_key_constraint do
          it "generates the expected sql for a basic foreign key constraint" do
            migration.add_foreign_key_constraint(:my_table, :my_column, :foreign_schema, :foreign_table, :foreign_column, name: :my_foreign_key)

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
            migration.add_foreign_key_constraint(:my_table, [:my_column, :my_other_column], :foreign_schema, :foreign_table, [:foreign_column, :other_foreign_column], name: :my_foreign_key)

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
              migration.add_foreign_key_constraint(:my_table, [:my_column, :my_other_column], :foreign_schema, :foreign_table, [:foreign_column, :other_foreign_column], name: :my_foreign_key, initially_deferred: true, deferrable: false)
            }.to raise_error DynamicMigrations::ActiveRecord::Migrators::DeferrableOptionsError
          end
        end
      end
    end
  end
end
