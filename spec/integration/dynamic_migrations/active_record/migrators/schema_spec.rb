# frozen_string_literal: true

RSpec.describe DynamicMigrations::ActiveRecord::Migrators do
  describe :Schema do
    describe "for a class which includes the Migrators Module" do
      let(:migration_class) {
        Class.new do
          include DynamicMigrations::ActiveRecord::Migrators

          # stub an execute method so we can validate the SQL created
          # rather than execute it
          def execute sql
            sql
          end
        end
      }

      let(:migration) { migration_class.new }

      describe "once the schema_name has been set on the module" do
        before(:each) do
          DynamicMigrations::ActiveRecord::Migrators.set_schema_name :my_schema
        end

        after(:each) do
          DynamicMigrations::ActiveRecord::Migrators.clear_schema_name
        end

        describe :create_schema do
          it "generates the expected sql" do
            expect(migration.create_schema).to eq <<~SQL
              CREATE SCHEMA my_schema;
            SQL
          end
        end

        describe :drop_schema do
          it "generates the expected sql" do
            expect(migration.drop_schema).to eq <<~SQL
              DROP SCHEMA my_schema;
            SQL
          end
        end
      end
    end
  end
end
