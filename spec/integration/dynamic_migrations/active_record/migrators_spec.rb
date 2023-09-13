# frozen_string_literal: true

RSpec.describe DynamicMigrations::ActiveRecord::Migrators do
  describe "for a class which includes this module" do
    let(:migration_class) {
      Class.new do
        include DynamicMigrations::ActiveRecord::Migrators
      end
    }

    let(:migration) { migration_class.new }

    describe :initialize do
      it "instantiates the class without error" do
        expect { migration_class.new }.not_to raise_error
      end
    end

    describe :schema_name do
      it "raises an error because the schema name has not been set yet" do
        expect {
          migration.schema_name
        }.to raise_error DynamicMigrations::ActiveRecord::Migrators::SchemaNameNotSetError
      end

      describe "once the schema_name has been set on the migration class" do
        before(:each) do
          migration_class.set_schema_name :public
        end

        it "returns the schema name" do
          expect(migration.schema_name).to eq :public
        end
      end
    end
  end
end
